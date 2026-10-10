# Bundled Google Fonts

The app's typography is Inter (weights 400, 600 and 700) and Roboto Mono
(weight 600) through the `google_fonts` package. When the font files below are
present in this folder, `google_fonts` loads them from the app bundle. When
they are missing it falls back to downloading them from `fonts.gstatic.com` on
every visit, after the first frame, which makes all text re-flow once the
fonts arrive.

`google_fonts` finds a file by its name, so the names must be exactly:

| File | Font |
|---|---|
| `Inter-Regular.ttf` | Inter 400 |
| `Inter-SemiBold.ttf` | Inter 600 |
| `Inter-Bold.ttf` | Inter 700 |
| `RobotoMono-SemiBold.ttf` | Roboto Mono 600 |

These are the same files the package downloads at runtime. Fetch them into this
folder with:

```bash
cd assets/google_fonts
curl -fsSL -o Inter-Regular.ttf      https://fonts.gstatic.com/s/a/15b294b67f2f8bbc04d990023ef4aec66502b87dc9040d84abe5f896ccb693de.ttf
curl -fsSL -o Inter-SemiBold.ttf     https://fonts.gstatic.com/s/a/334bb2c51aeba5f566abac8d03a7e75ab3234d6926b52e92a85dc704129258b5.ttf
curl -fsSL -o Inter-Bold.ttf         https://fonts.gstatic.com/s/a/76121a34a606cc8a0e1ef5a47d2b9ba9678c41f5c852d63eb28f62069373bfad.ttf
curl -fsSL -o RobotoMono-SemiBold.ttf https://fonts.gstatic.com/s/a/6693e9456a6412291b6ef0b72b5db1f562392e7f75a7e1665235c48687925d14.ttf
```

Expected sizes: 324 796, 326 024, 326 444 and 79 180 bytes. Both fonts are
published under the SIL Open Font License.

If another weight or an italic style is ever used through `GoogleFonts.inter`,
add its file here too, otherwise that one variant is fetched at runtime. The
folder is declared as an asset directory in `pubspec.yaml`, so new files are
picked up by the next build without further changes.
