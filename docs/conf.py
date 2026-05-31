"""Sphinx config for the nSTAT intro/landing site.

Mirrors the nSTAT-python doc stack (sphinx + myst-parser + sphinx-rtd-theme +
sphinx-design) so both ports present a consistent aesthetic.

Builds in CI via `.github/workflows/docs.yml`; deploys to GitHub Pages.
"""

project = "nSTAT"
author = "Iahn Cajigas, Wasim Malik, Emery N. Brown"
copyright = "2012-2026"
release = "1.4.0"

extensions = [
    "myst_parser",
    "sphinx_design",
]

# Allow both .md (MyST) and .rst sources.
source_suffix = {
    ".md": "markdown",
    ".rst": "restructuredtext",
}
master_doc = "index"   # generates index.html at the site root

# MyST extensions used by index.md
myst_enable_extensions = [
    "colon_fence",    # ::: directives in Markdown
    "deflist",
    "linkify",
    "html_image",
]

# Auto-generate anchor IDs for headings up to depth 3 so in-page links
# like (#tour-6-...) resolve without manual {#anchor} attributes.
myst_heading_anchors = 3

# HTML theme — same as nSTAT-python (Read-the-Docs).
html_theme = "sphinx_rtd_theme"
html_theme_options = {
    "logo_only": False,
    "navigation_depth": 3,
    "collapse_navigation": False,
}
html_logo = "figures/example03/fig01_simulated_and_real_rasters.png"
html_title = "nSTAT"
html_show_copyright = False
html_show_sphinx = False

# Serve the existing helpfiles/ HTML alongside the built site so links from
# intro.md to e.g. HelloNstat.html resolve at <site_root>/HelloNstat.html.
# The relative path is relative to this conf.py (docs/conf.py → ../helpfiles).
import os
_HERE = os.path.dirname(os.path.abspath(__file__))
html_extra_path = [os.path.join(_HERE, "..", "helpfiles")]

# Static assets local to docs/ (currently empty; ready for custom CSS).
html_static_path: list[str] = []

exclude_patterns = [
    "_build",
    "superpowers/**",
    "verification/**",
    "DEVPLAN.md",
]
