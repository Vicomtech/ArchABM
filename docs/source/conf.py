# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

import os
import sys

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.

sys.path.insert(0, os.path.abspath("../.."))
sys.path.insert(0, os.path.abspath("../../archABM"))


# -- Project information -----------------------------------------------------

project = "archABM"
copyright = "2021, Vicomtech"
author = "Vicomtech"

# The full version, including alpha/beta/rc tags
release = "0.4.1"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx.ext.napoleon",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    'sphinx.ext.intersphinx',
    'sphinx.ext.mathjax',
    'sphinxcontrib.bibtex',
    'sphinx.ext.viewcode',
    "sphinx_rtd_theme",
    'sphinxcontrib.tikz',
    'sphinx-jsonschema',
    "sphinx.ext.autosectionlabel",
    "sphinx_copybutton",
    'sphinxcontrib.programoutput',
    'sphinx_tabs.tabs'
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]
source_suffix = '.rst'
gettext_compact = False

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

pygments_style = "sphinx"

# Copy button
copybutton_prompt_text = r">>> |\.\.\. |\$ |In \[\d*\]: | {2,5}\.\.\.: | {5,8}: "
copybutton_prompt_is_regexp = True

# The master toctree document.
master_doc = "contents"


# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
    'http://docs.python.org/3/': None,
    'https://simpy.readthedocs.io/en/latest/': None
}

# Autodoc
autosummary_generate = True
autodoc_member_order = 'bysource'

# Bibtex
bibtex_bibfiles = ['references.bib']
bibtex_encoding = 'latin'
# bibtex_default_style = 'plain'

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#

html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["_static"]
html_favicon = "_static/favicon.png"
html_logo = "_static/logo_3.png"
html_show_sourcelink = True

html_context = {
  'display_github': True,
  'github_user': 'Vicomtech',
  'github_repo': 'ArchABM',
  'github_version': 'develop/docs/source/',
}

html_theme_options = {
    'logo_only': True,
    'display_version': True,
    'prev_next_buttons_location': 'bottom',
    'style_external_links': False,
    'style_nav_header_background': '#2980B9',
    'vcs_pageview_mode': 'blob',
    # Toc options
    'collapse_navigation': False,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False
}


def setup(app):
    app.add_css_file('my_theme.css')
