URW++ GhostScript Fonts
=======================

These are WOFF2 versions of [fonts](https://en.wikipedia.org/wiki/Ghostscript#Free_fonts)
included with every [Ghostscript](https://www.ghostscript.com/) installation.
The typefaces were originally created for Artifex Software by German typeface foundry
[URW++](https://www.urwpp.de/), who subsequently released them under the
[GNU Affero General Public License](https://www.gnu.org/licenses/agpl.html).

Source files for the Core35 fonts are available from
[`git.ghostscript.com/urw-core35-fonts.git`](http://git.ghostscript.com/?p=urw-core35-fonts.git;a=summary),
where they remain available in four different formats: AFM, OpenType, Type1, and TrueType.



Installation
------------
Either extract the fonts from a tarballed release, or install this module just like any other:

~~~sh
npm install urw-core35-fonts
~~~

__Take note:__  
There's no JavaScript in this module.
The package's "entry point" is its main stylesheet, [`index.css`](./index.css),
which holds `@font-face` rules for each bundled font-family and variation thereof:

	node_modules
	    └── urw-core35-fonts
	        ├── index.css
	        └── fonts
	            ├── C059-BdIta.woff2
	            ├── NimbusMonoPS-Bold.woff2
	            ├── NimbusMonoPS-BoldItalic.woff2
	            ├── URWBookman-DemiItalic.woff2
	            └── ... +32 other items

You can attach the font-sheet using an HTML `link`:

~~~html
<link rel="stylesheet" type="text/css" href="node_modules/urw-core35-fonts/index.css" />
~~~


Or, if you need a more programmatic way to locate the package or its assets,
use [`require.resolve`](https://nodejs.org/api/globals.html#globals_require_resolve):

~~~js
const cssPath = require.resolve("urw-core35-fonts/index.css");
console.log(cssPath) => "/foo/node_modules/urw-core35-fonts/index.css";
~~~



License
-------
These fonts are released under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl.html).
Verbatim copies of the Ghostscript project's licensing info are included with this package;
see [`COPYING`](COPYING) and [`LICENSE`](LICENSE).
