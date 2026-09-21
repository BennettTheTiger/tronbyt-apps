"""
Applet: Spectrum Local News
Summary: Local headlines from Spectrum
Description: View local news feeds from Spectrum News.
Author: Bennett Schoonerman
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/spectrum_logo.png", SPECTRUM_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

DEFAULT_FEED = "rochester"

DEFAULT_RSS_URL = "https://spectrumlocalnews.com/services/contentfeed.nys%7crochester%7cnews.landing.rss"

FEED_OPTIONS = [
    schema.Option(display = "Rochester", value = "rochester"),
    schema.Option(display = "New York", value = "new_york"),
    schema.Option(display = "California", value = "california"),
    schema.Option(display = "Florida", value = "florida"),
    schema.Option(display = "Texas", value = "texas"),
]

def get_feed_url(feed):
    if feed == "rochester":
        return DEFAULT_RSS_URL
    if feed == "new_york":
        return DEFAULT_RSS_URL
    if feed == "california":
        return DEFAULT_RSS_URL
    if feed == "florida":
        return DEFAULT_RSS_URL
    if feed == "texas":
        return DEFAULT_RSS_URL
    return DEFAULT_RSS_URL

MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

def pad2(value):
    s = str(value)
    if len(s) == 1:
        return "0" + s
    return s

def parse_rfc822_to_epoch(value):
    if value == "":
        return None

    s = value.strip()
    if "," in s:
        s = s.split(",", 1)[1].strip()

    parts = [p for p in s.split(" ") if p != ""]
    if len(parts) < 5:
        return None

    day = int(parts[0])
    month = MONTHS.get(parts[1][:3].capitalize())
    year = int(parts[2])
    clock = parts[3]
    meridiem = ""
    tz = ""

    if len(parts) >= 6:
        meridiem = parts[4]
        tz = parts[5]
    else:
        tz = parts[4]

    if month == None:
        return None

    hhmmss = clock.split(":")
    if len(hhmmss) < 2:
        return None

    hour = int(hhmmss[0])
    minute = int(hhmmss[1])
    second = 0
    if len(hhmmss) >= 3:
        second = int(hhmmss[2])

    if meridiem.upper() == "PM" and hour < 12:
        hour = hour + 12
    if meridiem.upper() == "AM" and hour == 12:
        hour = 0

    tz_offset = 0
    tz_upper = tz.upper()
    if tz_upper == "GMT" or tz_upper == "UTC":
        tz_offset = 0
    elif tz_upper == "EDT":
        tz_offset = -4
    elif tz_upper == "EST":
        tz_offset = -5
    elif tz_upper == "CDT":
        tz_offset = -5
    elif tz_upper == "CST":
        tz_offset = -6
    elif tz_upper == "MDT":
        tz_offset = -6
    elif tz_upper == "MST":
        tz_offset = -7
    elif tz_upper == "PDT":
        tz_offset = -7
    elif tz_upper == "PST":
        tz_offset = -8
    elif tz.startswith("+") or tz.startswith("-"):
        tz_offset = 0

    tz_offset_str = "Z"
    if tz_offset < 0:
        tz_offset_str = "-" + pad2(abs(tz_offset)) + ":00"
    elif tz_offset > 0:
        tz_offset_str = "+" + pad2(tz_offset) + ":00"

    iso = str(year) + "-" + pad2(month) + "-" + pad2(day) + "T" + pad2(hour) + ":" + pad2(minute) + ":" + pad2(second) + tz_offset_str
    parsed = time.parse_time(iso)
    if parsed == None:
        return None
    return parsed.unix

def parse_max_age_hours(value, default = 24):
    if value == "":
        return default
    if value.isdigit():
        parsed = int(value)
        if parsed < 1:
            return 1
        return parsed
    return default


def get_headlines(url, max_age_hours = 24):
    cache_key = "{}|{}|{}".format(url, max_age_hours, int(time.now().unix / 3600))
    cached = cache.get(cache_key)
    if cached != None:
        return cached.split("||")

    rep = http.get(url, ttl_seconds = 1800)
    if rep.status_code != 200:
        return ["Spectrum News unavailable"]

    doc = xpath.loads(rep.body())
    items = doc.query_all_nodes("/rss/channel/item")
    stories = []
    cutoff = max_age_hours * 3600
    now_epoch = time.now().unix
    for item in items:
        title = item.query("/title")
        pub_date = item.query("/pubDate")
        if title == "":
            continue

        if pub_date != "":
            pub_epoch = parse_rfc822_to_epoch(pub_date)
            if pub_epoch != None:
                if (now_epoch - pub_epoch) > cutoff:
                    continue
            else:
                continue

        stories.append(title)

    if len(stories) == 0:
        stories = ["No recent headlines available"]

    cache.set(cache_key, "||".join(stories), ttl_seconds = 1800)
    return stories

def main(config):
    feed = config.str("feed", DEFAULT_FEED)
    speed_value = config.get("speed", "100")
    speed = 100
    if speed_value == "200":
        speed = 200
    elif speed_value == "50":
        speed = 50
    else:
        speed = 100

    raw_max_age = config.get("max_age_hours", "24")
    max_age_hours = parse_max_age_hours(raw_max_age, 24)

    url = get_feed_url(feed)
    headlines = get_headlines(url, max_age_hours)

    items = [
        render.Image(
            src = SPECTRUM_LOGO_ASSET.readall(),
            width = 64,
            height = 36,
        ),
        render.Box(width = 64, height = 1, color = "#333333"),
    ]
    for headline in headlines:
        items.append(render.Box(width = 64, height = 1, color = "#000000"))
        items.append(render.WrappedText(content = headline, color = "#dddddd", width = 64))
        items.append(render.Box(width = 64, height = 1, color = "#000000"))
        items.append(render.Box(width = 64, height = 1, color = "#333333"))

    return render.Root(
        delay = speed,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Marquee(
                    height = 36,
                    offset_start = 24,
                    scroll_direction = "vertical",
                    child = render.Column(children = items),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feed",
                name = "Region",
                desc = "Choose a Spectrum market.",
                icon = "map",
                default = DEFAULT_FEED,
                options = FEED_OPTIONS,
            ),
            schema.Text(
                id = "max_age_hours",
                name = "Max age (hours)",
                desc = "Hide headlines older than this many hours.",
                icon = "clock",
                default = "24",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Ticker Speed",
                desc = "Choose the speed of the ticker.",
                icon = "globe",
                default = "100",
                options = [
                    schema.Option(display = "Slow", value = "200"),
                    schema.Option(display = "Medium", value = "100"),
                    schema.Option(display = "Fast", value = "50"),
                ],
            ),
        ],
    )
