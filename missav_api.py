#!/usr/bin/env python3
"""
MissAV API Library — Reverse Engineered
========================================
Scraper, search, stream resolver for missav.ws

Requirements:
    pip install curl-cffi beautifulsoup4 lxml
  
  Built-in for Python 3.11+"""
  
import os
import re
import time
import hmac
import hashlib
import logging
import asyncio
import argparse
from urllib.parse import quote, urlparse
from typing import Optional, Any
from dataclasses import dataclass, field

# === NETWORKING ===
try:
    from curl_cffi.requests import AsyncSession as CurlAsyncSession
    from curl_cffi.requests import Session as CurlSession
    HAS_CURL_CFFI = True
except ImportError:
    HAS_CURL_CFFI = False

try:
    import requests as std_requests
except ImportError:
    std_requests = None

from bs4 import BeautifulSoup

# ══════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════

BASE_URL = "https://missav.ws"
RECOMBEE_HOST = "client-rapi-missav.recombee.com"
DATABASE_ID = "missav-default"
PUBLIC_TOKEN = "Ikkg568nlM51RHvldlPvc2GzZPE9R4XGzaH9Qj4zK9npbbbTly1gj9K4mgRn0QlV"

SURRIT_PREFIX = "https://surrit.com/"
SURRIT_SUFFIX = "/playlist.m3u8"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,ja;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}

STREAM_HEADERS = {
    "User-Agent": HEADERS["User-Agent"],
    "Accept": "*/*",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "cross-site",
}

# Search result extraction patterns
DIVIDER_RE = re.compile(r"(\d+)(?:div|divider|cat10|cat12)")

logger = logging.getLogger("missav_api")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")


# ══════════════════════════════════════════════════════════════
# HMAC SIGNATURE (Recombee Search API)
# ══════════════════════════════════════════════════════════════

def _sign_path(path: str, token: str) -> str:
    """
    Reproduce _signUrl(path) from the site's JavaScript.
    1) Build /{databaseId}{path}?frontend_timestamp=UNIX
    2) HMAC-SHA1 that string with the public token
    3) Append &frontend_sign=hexdigest
    """
    ts = int(time.time())
    unsigned = f"/{DATABASE_ID}{path}"
    if "?" in unsigned:
        unsigned += f"&frontend_timestamp={ts}"
    else:
        unsigned += f"?frontend_timestamp={ts}"
    signature = hmac.new(
        token.encode("utf-8"),
        unsigned.encode("utf-8"),
        hashlib.sha1,
    ).hexdigest()
    return unsigned + f"&frontend_sign={signature}"


# ══════════════════════════════════════════════════════════════
# DATA CLASSES
# ══════════════════════════════════════════════════════════════

@dataclass
class VideoInfo:
    """Metadata for a single video"""
    url: str
    title: Optional[str] = None
    thumbnail: Optional[str] = None
    publish_date: Optional[str] = None
    length: Optional[str] = None
    keywords: Optional[str] = None
    actresses: list[str] = field(default_factory=list)
    makers: list[str] = field(default_factory=list)
    genres: list[str] = field(default_factory=list)
    stream_url: Optional[str] = None  # m3u8 URL

    def __repr__(self):
        return f"<Video {self.title or self.url}>"


@dataclass
class SearchResult:
    """A single search result"""
    url: str
    title: Optional[str] = None
    thumbnail: Optional[str] = None
    length: Optional[str] = None
    actresses: list[str] = field(default_factory=list)
    subtitles: dict = field(default_factory=dict)  # {lang: bool}
    uncensored: bool = False
    has_chinese_sub: bool = False
    has_english_sub: bool = False


@dataclass
class StreamInfo:
    """Resolved stream information"""
    playlist_url: str  # Base m3u8 URL
    headers: dict = field(default_factory=dict)
    qualities: dict = field(default_factory=dict)  # {quality: url}
    master_url: Optional[str] = None  # Highest quality stream URL


# ══════════════════════════════════════════════════════════════
# STREAM RESOLVER
# ══════════════════════════════════════════════════════════════

def _extract_m3u8_from_packed_js(content: str) -> Optional[str]:
    """
    Extract m3u8 URL from packed/obfuscated JavaScript.
    Pattern: 'm3u8...|part1|part2|...|partN|...video'
    The parts are reversed and used to build the URL.
    """
    match = re.search(r"'m3u8(.*?)video'", content, re.DOTALL)
    if not match:
        return None
    
    url_parts = match.group(1).split("|")[::-1]  # Reverse
    if len(url_parts) < 9:
        return None
    
    # Build: protocol://subdomain.domain/part1-part2-part3-part4-part5/playlist.m3u8
    try:
        url = (
            f"{url_parts[1]}://{url_parts[2]}.{url_parts[3]}/"
            f"{url_parts[4]}-{url_parts[5]}-{url_parts[6]}-{url_parts[7]}-{url_parts[8]}"
            f"/playlist.m3u8"
        )
        return url
    except IndexError:
        return None


def _extract_m3u8_from_html(content: str) -> Optional[str]:
    """
    Extract m3u8 URL from page HTML using multiple fallback patterns.
    Priority: packed JS > direct m3u8 > surrit UUID
    """
    # 1. Packed JS extraction
    result = _extract_m3u8_from_packed_js(content)
    if result:
        return result

    # 2. Direct m3u8 URL
    direct = re.search(r'https?://[^\s"\'<>]+/playlist\.m3u8', content)
    if direct:
        return direct.group(0)

    # 3. Surrit UUID pattern
    surrit = re.search(r'surrit\.com[/\\]+([a-f0-9-]{36})', content)
    if surrit:
        return f"{SURRIT_PREFIX}{surrit.group(1)}{SURRIT_SUFFIX}"

    # 4. Video element src
    vid = re.search(r'src=["\']+(https://surrit\.com/[^"\']+)', content)
    if vid:
        return vid.group(1)

    return None


def _build_stream_headers(movie_url: str) -> dict:
    """Build required headers for stream access"""
    parsed = urlparse(movie_url)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    return {
        **STREAM_HEADERS,
        "Referer": movie_url,
        "Origin": origin,
    }


async def resolve_stream(
    movie_id: str,
    base_url: str = BASE_URL,
    quality: Optional[str] = None,
    session: Optional[Any] = None,
) -> Optional[StreamInfo]:
    """
    Resolve a video stream URL from its movie ID.
    
    Args:
        movie_id: Video ID (e.g. 'ssis-406', 'fc2-ppv-4968310')
        base_url: MissAV base URL
        quality: Target quality ('720p', '1080p', etc.)
        session: Optional curl_cffi AsyncSession
        
    Returns:
        StreamInfo with m3u8 URL and headers, or None
    """
    movie_url = f"{base_url}/en/{movie_id}"
    logger.info(f"Resolving stream: {movie_url}")

    # Fetch page HTML
    close_session = False
    if session is None:
        if HAS_CURL_CFFI:
            session = CurlAsyncSession(impersonate="chrome")
        elif std_requests:
            session = std_requests.Session()
            session.headers.update(HEADERS)
        else:
            raise ImportError("Install curl-cffi or requests: pip install curl-cffi")
        close_session = True

    try:
        if hasattr(session, "get") and hasattr(session, "__aenter__"):
            # curl_cffi async
            resp = await session.get(movie_url, headers=HEADERS, timeout=15)
            html = resp.text
        elif hasattr(session, "get"):
            # requests sync
            resp = session.get(movie_url, headers=HEADERS, timeout=15)
            html = resp.text
        else:
            raise ValueError("Unsupported session type")
    finally:
        if close_session:
            if hasattr(session, "close"):
                await session.close() if asyncio.iscoroutinefunction(session.close) else session.close()

    # Extract m3u8 URL
    playlist_url = _extract_m3u8_from_html(html)
    if not playlist_url:
        logger.error(f"Could not extract m3u8 URL from {movie_id}")
        return None

    logger.info(f"Found playlist: {playlist_url}")

    # Fetch playlist to get available qualities
    headers = _build_stream_headers(movie_url)
    qualities = {}

    try:
        if HAS_CURL_CFFI:
            async with CurlAsyncSession(impersonate="chrome") as s:
                resp = await s.get(playlist_url, headers=headers, timeout=10)
                content = resp.text
        else:
            resp = std_requests.get(playlist_url, headers=headers, timeout=10)
            content = resp.text

        # Parse master playlist for quality variants
        current_resolution = None
        for line in content.splitlines():
            res_match = re.search(r'RESOLUTION=(\d+)x(\d+)', line)
            if res_match:
                width = int(res_match.group(1))
                if width >= 1920:
                    current_resolution = "1080p"
                elif width >= 1280:
                    current_resolution = "720p"
                elif width >= 854:
                    current_resolution = "480p"
                elif width >= 640:
                    current_resolution = "360p"
                else:
                    current_resolution = f"{width}p"
            elif line.strip() and not line.startswith("#") and current_resolution:
                stream_url = line.strip() if line.startswith("http") else "/".join(playlist_url.split("/")[:-1]) + "/" + line.strip()
                qualities[current_resolution] = stream_url
                current_resolution = None
    except Exception as e:
        logger.warning(f"Could not fetch master playlist: {e}")

    # Pick best quality
    best_url = playlist_url
    if quality and quality in qualities:
        best_url = qualities[quality]
    elif qualities:
        # Prefer highest quality
        order = ["1080p", "720p", "480p", "360p"]
        for q in order:
            if q in qualities:
                best_url = qualities[q]
                break

    return StreamInfo(
        playlist_url=playlist_url,
        headers=headers,
        qualities=qualities,
        master_url=best_url,
    )


# ══════════════════════════════════════════════════════════════
# SEARCH API (Recombee)
# ══════════════════════════════════════════════════════════════

async def search_videos(
    query: str,
    count: int = 24,
    session: Optional[Any] = None,
    base_url: str = BASE_URL,
) -> list[VideoInfo]:
    """
    Search videos via MissAV's Recombee recommendation API.
    
    Uses the site's own search endpoint (same as the website search bar).
    HMAC-SHA1 signed request to bypass authentication.
    
    Args:
        query: Search term (actress name, title, ID, etc.)
        count: Number of results to return
        session: Optional curl_cffi session
        base_url: MissAV base URL
        
    Returns:
        List of VideoInfo with URLs and metadata
    """
    user_id = f"anon_{hashlib.md5(str(time.time()).encode()).hexdigest()[:16]}"
    path = f"/search/users/{quote(user_id, safe='')}/items/"
    
    body = {
        "searchQuery": query.strip(),
        "count": count,
        "cascadeCreate": True,
        "returnProperties": True,
    }

    signed_path = _sign_path(path, PUBLIC_TOKEN)
    url = f"https://{RECOMBEE_HOST}{signed_path}"

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Origin": base_url,
        "Referer": f"{base_url}/",
    }

    close_session = False
    if session is None:
        if HAS_CURL_CFFI:
            session = CurlAsyncSession(impersonate="chrome")
        else:
            raise ImportError("Install curl-cffi: pip install curl-cffi")
        close_session = True

    try:
        resp = await session.post(url, json=body, headers=headers, timeout=9)
        data = resp.json()
    finally:
        if close_session:
            await session.close()

    recomms = data.get("recomms", [])
    results = []

    for rec in recomms:
        vid_id = rec.get("id", "")
        props = rec.get("values", {})
        
        video = VideoInfo(
            url=f"{base_url}/en/{vid_id}",
            title=props.get("title"),
            thumbnail=props.get("image_url"),
            publish_date=props.get("release_date"),
            length=props.get("length"),
            keywords=props.get("keywords"),
            actresses=[props.get("actress", "")] if props.get("actress") else [],
        )
        results.append(video)

    logger.info(f"Search '{query}': {len(results)} results")
    return results


# ══════════════════════════════════════════════════════════════
# HTML SCRAPER (for pages without API access)
# ══════════════════════════════════════════════════════════════

async def scrape_video_page(
    url: str,
    session: Optional[Any] = None,
    resolve_stream_url: bool = True,
) -> Optional[VideoInfo]:
    """
    Scrape a video page for metadata + optional stream URL.
    
    Args:
        url: Full video page URL
        session: Optional curl_cffi session
        resolve_stream_url: Also extract the m3u8 stream URL
        
    Returns:
        VideoInfo with all available metadata
    """
    close_session = False
    if session is None:
        if HAS_CURL_CFFI:
            session = CurlAsyncSession(impersonate="chrome")
        else:
            raise ImportError("Install curl-cffi: pip install curl-cffi")
        close_session = True

    try:
        resp = await session.get(url, headers=HEADERS, timeout=15)
        html = resp.text
    finally:
        if close_session:
            await session.close()

    soup = BeautifulSoup(html, "lxml")

    # Title
    title = None
    og_title = soup.find("meta", property="og:title")
    if og_title:
        title = og_title.get("content", "").strip()
    if not title:
        h1 = soup.find("h1")
        if h1:
            title = h1.get_text(strip=True)

    # Thumbnail
    thumbnail = None
    og_image = soup.find("meta", property="og:image")
    if og_image:
        thumbnail = og_image.get("content", "").strip()
    if not thumbnail:
        vid = soup.find("video", {"data-poster": True})
        if vid:
            thumbnail = vid.get("data-poster")

    # Date
    publish_date = None
    og_date = soup.find("meta", property="og:video:release_date")
    if og_date:
        publish_date = og_date.get("content", "").strip()

    # Length
    length = None
    og_len = soup.find("meta", property="og:video:duration")
    if og_len:
        length = og_len.get("content", "").strip()
    if not length:
        time_node = soup.select_one(".plyr__time--duration")
        if time_node:
            length = time_node.get_text(strip=True)

    # Keywords / Tags
    keywords = None
    kw_node = soup.find("meta", attrs={"name": "keywords"})
    if kw_node:
        keywords = kw_node.get("content", "").strip()

    # Actresses
    actresses = []
    for a in soup.select("a[href*='/actresses/']"):
        name = a.get_text(strip=True)
        if name:
            actresses.append(name)

    # Stream URL
    stream_url = None
    if resolve_stream_url:
        stream_url = _extract_m3u8_from_html(html)

    return VideoInfo(
        url=url,
        title=title,
        thumbnail=thumbnail,
        publish_date=publish_date,
        length=length,
        keywords=keywords,
        actresses=actresses,
        stream_url=stream_url,
    )


async def scrape_listing_page(
    url: str,
    session: Optional[Any] = None,
) -> list[SearchResult]:
    """
    Scrape a listing/category page (new, release, genre, etc.)
    
    Args:
        url: Listing page URL
        session: Optional curl_cffi session
        
    Returns:
        List of SearchResult
    """
    close_session = False
    if session is None:
        if HAS_CURL_CFFI:
            session = CurlAsyncSession(impersonate="chrome")
        else:
            raise ImportError("Install curl-cffi: pip install curl-cffi")
        close_session = True

    try:
        resp = await session.get(url, headers=HEADERS, timeout=15)
        html = resp.text
    finally:
        if close_session:
            await session.close()

    soup = BeautifulSoup(html, "lxml")
    results = []

    # Find all video cards (each has an image + title + duration)
    for card in soup.select("a[href*='/en/']"):
        href = card.get("href", "")
        if not href or href.endswith("#") or "/actresses" in href or "/genres" in href:
            continue

        # Skip non-video links
        img = card.find("img")
        if not img:
            continue

        # Extract metadata
        title_text = img.get("alt", "").strip() or card.get_text(strip=True)
        if not title_text:
            continue

        full_url = href if href.startswith("http") else f"{BASE_URL}{href}"

        # Check for badges
        badges = card.find_all("span", class_=lambda c: c and "badge" in c.lower() if c else False)
        uncensored = any("uncensored" in b.get_text().lower() for b in badges)
        has_cn = any("chinese" in b.get_text().lower() for b in badges)
        has_en = any("english" in b.get_text().lower() for b in badges)

        # Duration
        duration_text = card.get_text(strip=True)
        duration_match = re.search(r'(\d+:\d+:\d+|\d+:\d+)', duration_text)
        duration = duration_match.group(1) if duration_match else None

        result = SearchResult(
            url=full_url,
            title=title_text,
            thumbnail=img.get("src"),
            length=duration,
            uncensored=uncensored,
            has_chinese_sub=has_cn,
            has_english_sub=has_en,
        )
        results.append(result)

    # Deduplicate by URL
    seen = set()
    unique = []
    for r in results:
        if r.url not in seen:
            seen.add(r.url)
            unique.append(r)

    logger.info(f"Scraped {len(unique)} videos from {url}")
    return unique


# ══════════════════════════════════════════════════════════════
# CATEGORY URLS
# ══════════════════════════════════════════════════════════════

URLS = {
    "new":           f"{BASE_URL}/en/new",
    "release":       f"{BASE_URL}/en/release",
    "uncensored":    f"{BASE_URL}/en/uncensored-leak",
    "english_sub":   f"{BASE_URL}/en/english-subtitle",
    "today_hot":     f"{BASE_URL}/en/today-hot",
    "weekly_hot":    f"{BASE_URL}/en/weekly-hot",
    "monthly_hot":   f"{BASE_URL}/en/monthly-hot",
    "actresses":     f"{BASE_URL}/en/actresses",
    "ranking":       f"{BASE_URL}/en/actresses/ranking",
    "genres":        f"{BASE_URL}/en/genres",
    "makers":        f"{BASE_URL}/en/makers",
    "vr":            f"{BASE_URL}/en/genres/VR",
    "fc2":           f"{BASE_URL}/en/fc2",
    "siro":          f"{BASE_URL}/en/siro",
    "luxu":          f"{BASE_URL}/en/luxu",
    "s_cute":        f"{BASE_URL}/en/scute",
    "madou":         f"{BASE_URL}/en/madou",
}


# ══════════════════════════════════════════════════════════════
# DOWNLOAD HELPER
# ══════════════════════════════════════════════════════════════

async def download_video(
    stream_info: StreamInfo,
    output_path: str = "./",
    filename: Optional[str] = None,
    session: Optional[Any] = None,
) -> bool:
    """
    Download video from resolved stream URL.
    Uses ffmpeg if available for HLS download, otherwise falls back to chunked.
    
    Args:
        stream_info: StreamInfo from resolve_stream()
        output_path: Directory to save to
        filename: Custom filename (without extension)
        session: Optional session for chunked download
        
    Returns:
        True if successful
    """
    url = stream_info.master_url or stream_info.playlist_url
    headers = stream_info.headers

    if not filename:
        filename = "video"

    output_file = os.path.join(output_path, f"{filename}.mp4")
    os.makedirs(output_path, exist_ok=True)

    # Build header arguments for ffmpeg
    header_args = []
    for k, v in headers.items():
        header_args.extend(["-headers", f"{k}: {v}\r\n"])

    # Try ffmpeg first
    try:
        cmd = ["ffmpeg", "-y", "-i", url] + header_args + ["-c", "copy", output_file]
        proc = await asyncio.create_subprocess_exec(
            *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )
        _, stderr = await proc.communicate()
        if proc.returncode == 0:
            logger.info(f"Downloaded: {output_file}")
            return True
        else:
            logger.warning(f"ffmpeg failed: {stderr.decode()[:200]}")
    except FileNotFoundError:
        logger.warning("ffmpeg not found, falling back to chunked download")

    # Fallback: chunked download of m3u8 segments
    logger.info("Using chunked m3u8 download")
    segment_index = 0

    if HAS_CURL_CFFI:
        async with CurlAsyncSession(impersonate="chrome") as s:
            # Fetch the playlist
            resp = await s.get(url, headers=headers, timeout=10)
            playlist_content = resp.text

            # Get segment URLs
            segments = []
            base = "/".join(url.split("/")[:-1])
            for line in playlist_content.splitlines():
                line = line.strip()
                if line and not line.startswith("#"):
                    seg_url = line if line.startswith("http") else f"{base}/{line}"
                    segments.append(seg_url)

            if not segments:
                logger.error("No segments found in playlist")
                return False

            logger.info(f"Found {len(segments)} segments")
            with open(output_file, "wb") as f:
                for seg_url in segments:
                    resp = await s.get(seg_url, headers=headers, timeout=30)
                    f.write(resp.content)
                    segment_index += 1
                    if segment_index % 50 == 0:
                        logger.info(f"  Downloaded {segment_index}/{len(segments)} segments")
    else:
        logger.error("curl-cffi required for chunked download")
        return False

    logger.info(f"Download complete: {output_file} ({segment_index} segments)")
    return True


# ══════════════════════════════════════════════════════════════
# CLI
# ══════════════════════════════════════════════════════════════

async def main_cli():
    parser = argparse.ArgumentParser(description="MissAV API — Search, Resolve, Download")
    sub = parser.add_subparsers(dest="command")

    # Search
    sp_search = sub.add_parser("search", help="Search videos")
    sp_search.add_argument("query", help="Search query")
    sp_search.add_argument("-n", "--count", type=int, default=10, help="Number of results")
    sp_search.add_argument("--no-stream", action="store_true", help="Skip stream URL resolution")

    # Resolve
    sp_resolve = sub.add_parser("resolve", help="Resolve stream URL")
    sp_resolve.add_argument("movie_id", help="Movie ID (e.g. ssis-406)")
    sp_resolve.add_argument("-q", "--quality", help="Quality (720p, 1080p)")

    # List
    sp_list = sub.add_parser("list", help="List videos from category")
    sp_list.add_argument("category", choices=list(URLS.keys()), help="Category name")
    sp_list.add_argument("-p", "--page", type=int, default=1, help="Page number")

    # Download
    sp_dl = sub.add_parser("download", help="Download a video")
    sp_dl.add_argument("movie_id", help="Movie ID")
    sp_dl.add_argument("-q", "--quality", help="Quality preference")
    sp_dl.add_argument("-o", "--output", default="./downloads", help="Output directory")

    args = parser.parse_args()

    if args.command == "search":
        results = await search_videos(args.query, count=args.count)
        for i, v in enumerate(results, 1):
            print(f"\n{i}. {v.title or v.url}")
            print(f"   URL: {v.url}")
            if v.actresses:
                print(f"   Actress: {', '.join(v.actresses)}")
            if v.length:
                print(f"   Length: {v.length}")
            if v.publish_date:
                print(f"   Date: {v.publish_date}")
            if v.stream_url:
                print(f"   Stream: {v.stream_url}")

    elif args.command == "resolve":
        stream = await resolve_stream(args.movie_id, quality=args.quality)
        if stream:
            print(f"Playlist: {stream.playlist_url}")
            print(f"Best URL: {stream.master_url}")
            print(f"Qualities: {', '.join(stream.qualities.keys()) or 'N/A'}")
            print(f"Headers: {stream.headers}")
        else:
            print("Failed to resolve stream")
            exit(1)

    elif args.command == "list":
        url = URLS[args.category]
        if args.page > 1:
            url += f"?page={args.page}"
        results = await scrape_listing_page(url)
        for i, r in enumerate(results, 1):
            badges = []
            if r.uncensored:
                badges.append("UC")
            if r.has_chinese_sub:
                badges.append("CN")
            if r.has_english_sub:
                badges.append("EN")
            badge_str = f" [{', '.join(badges)}]" if badges else ""
            print(f"{i:3d}. {r.title[:80]}{badge_str}")
            if r.length:
                print(f"     Duration: {r.length}")
            print(f"     URL: {r.url}")

    elif args.command == "download":
        print(f"Resolving stream for {args.movie_id}...")
        stream = await resolve_stream(args.movie_id, quality=args.quality)
        if not stream:
            print("Failed to resolve stream")
            exit(1)

        print(f"Stream resolved: {stream.master_url}")
        print(f"Downloading to {args.output}/...")

        success = await download_video(stream, output_path=args.output, filename=args.movie_id)
        if success:
            print("Download complete!")
        else:
            print("Download failed")
            exit(1)

    else:
        parser.print_help()


if __name__ == "__main__":
    asyncio.run(main_cli())
