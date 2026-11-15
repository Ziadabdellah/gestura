import html
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from legal_text import CONTACT, CONTROLLER, DELETION, LANGUAGES, PRIVACY, UPDATED
from terms_text import TERMS

ROOT = pathlib.Path(__file__).resolve().parent.parent
PUBLIC = ROOT / "firebase" / "hosting"
SITE = "https://gestura-prod.web.app"
PACKAGE = "app.gestura.com"
APPLE_TEAM = "43Y35JK32H"
SIGNING_SHA256 = [
    "BD:62:24:69:87:04:91:15:C8:71:81:6B:9E:C2:93:D1:A1:75:32:DA:FA:35:D8:F9:11:31:57:5A:00:81:6E:D2",
]

STYLE = """
:root{color-scheme:light dark;--bg:#F8F6F1;--text:#14222B;--muted:#4A5A63;--accent:#0B6E69;--card:#FFFFFF;--line:#E2DED5}
@media (prefers-color-scheme:dark){:root{--bg:#0E1517;--text:#E4ECEA;--muted:#A7B6B4;--accent:#62D3C6;--card:#16211F;--line:#27322F}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font:17px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,"Noto Sans Arabic",sans-serif}
main{max-width:720px;margin:0 auto;padding:32px 20px 64px}
header{display:flex;align-items:center;gap:12px;margin-bottom:8px}
.mark{width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#15877F,#085550)}
h1{font-size:28px;line-height:1.25;margin:16px 0 4px}
h2{font-size:19px;margin:32px 0 8px;color:var(--accent)}
p,li{margin:8px 0}
a{color:var(--accent)}
nav{display:flex;flex-wrap:wrap;gap:8px 16px;font-size:15px}
nav a[aria-current]{font-weight:700;text-decoration:none}
.muted{color:var(--muted);font-size:15px}
section.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:8px 20px;margin-top:24px}
""".strip()


def page(lang, title, body):
    direction = LANGUAGES[lang][1]
    return (
        "<!doctype html>\n"
        f'<html lang="{lang}" dir="{direction}">\n'
        "<head>\n"
        '<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f"<title>{html.escape(title)}</title>\n"
        f"<style>{STYLE}</style>\n"
        "</head>\n"
        "<body>\n<main>\n"
        '<header><div class="mark" aria-hidden="true"></div><strong>Gestura</strong></header>\n'
        f"{body}"
        "</main>\n</body>\n</html>\n"
    )


def fill(text):
    return (
        html.escape(text)
        .replace("{controller}", html.escape(CONTROLLER))
        .replace("{contact}", f'<a href="mailto:{CONTACT}">{CONTACT}</a>')
        .replace("{delete_url}", f'<a href="{SITE}/delete-account">{SITE}/delete-account</a>')
        .replace("{date}", UPDATED)
    )


def language_nav(current, path):
    links = []
    for code, (name, _) in LANGUAGES.items():
        current_attr = ' aria-current="page"' if code == current else ""
        links.append(f'<a href="/{path}/{code}" lang="{code}"{current_attr}>{html.escape(name)}</a>')
    return "<nav>" + "".join(links) + "</nav>\n"


def document(texts, path, lang):
    text = texts[lang]
    body = [language_nav(lang, path), f"<h1>{html.escape(text['title'])}</h1>\n"]
    body.append(f'<p class="muted">{fill(text["updated"])}</p>\n')
    for heading, paragraphs in text["sections"]:
        body.append(f"<h2>{html.escape(heading)}</h2>\n")
        body.extend(f"<p>{fill(paragraph)}</p>\n" for paragraph in paragraphs)
    return page(lang, text["title"], "".join(body))


def privacy(lang):
    return document(PRIVACY, "privacy", lang)


def terms(lang):
    return document(TERMS, "terms", lang)


def deletion():
    body = ["<h1>Delete your Gestura account</h1>\n"]
    for lang, (name, direction) in LANGUAGES.items():
        text = DELETION[lang]
        steps = "".join(f"<li>{fill(step)}</li>" for step in text["steps"])
        body.append(
            f'<section class="card" lang="{lang}" dir="{direction}" id="{lang}">'
            f"<h2>{html.escape(text['title'])}</h2><ol>{steps}</ol></section>\n"
        )
    return page("en", "Delete your Gestura account", "".join(body))


def home():
    body = (
        "<h1>Gestura</h1>\n"
        "<p>Sign language, in your hands.</p>\n"
        '<p><a href="/privacy">Privacy policy</a> · <a href="/terms">Terms of use</a> · <a href="/delete-account">Delete your account</a></p>\n'
    )
    return page("en", "Gestura", body)


def not_found():
    body = '<h1>Page not found</h1>\n<p><a href="/">Gestura</a></p>\n'
    return page("en", "Page not found", body)


def asset_links():
    return json.dumps(
        [
            {
                "relation": ["delegate_permission/common.handle_all_urls"],
                "target": {
                    "namespace": "android_app",
                    "package_name": PACKAGE,
                    "sha256_cert_fingerprints": SIGNING_SHA256,
                },
            }
        ],
        indent=2,
    ) + "\n"


def apple_app_site_association():
    return json.dumps(
        {
            "applinks": {
                "details": [
                    {
                        "appIDs": [f"{APPLE_TEAM}.{PACKAGE}"],
                        "components": [{"/": "/sign/*"}],
                    }
                ]
            }
        },
        indent=2,
    ) + "\n"


def shared_sign():
    body = (
        "<h1>A sign on Gestura</h1>\n"
        "<p>Open this link on a phone with Gestura installed to see the sign.</p>\n"
        '<p><a href="/">Gestura</a></p>\n'
    )
    return page("en", "A sign on Gestura", body)


def write(path, content):
    target = PUBLIC / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def main():
    write("index.html", home())
    write("404.html", not_found())
    write("privacy/index.html", privacy("en"))
    for lang in LANGUAGES:
        write(f"privacy/{lang}.html", privacy(lang))
    write("terms/index.html", terms("en"))
    for lang in LANGUAGES:
        write(f"terms/{lang}.html", terms(lang))
    write("delete-account/index.html", deletion())
    write("sign.html", shared_sign())
    write(".well-known/assetlinks.json", asset_links())
    write(".well-known/apple-app-site-association", apple_app_site_association())


if __name__ == "__main__":
    main()
