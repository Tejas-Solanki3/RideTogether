# Native Android assets

- `assets/images/welcome_car.jpg`: AI-generated color campus/automotive editorial image created for the redesigned welcome and Home screens. It does not depict real RideTogether students or a real Greenfield University.
- `assets/svg/logo.svg` and `android/.../drawable/rt_launcher.xml`: original monochrome route-arrow branding.
- `RouteMap` in Dart: original grayscale illustrative map, not GPS/navigation data.
- `assets/icons/*.svg`: locally bundled Lucide outline icons. The upstream license is included at `assets/icons/LICENSE`.
- `assets/fonts/Manrope.ttf`: Manrope variable font from Google Fonts; SIL Open Font License included at `assets/fonts/OFL.txt`.
- Sample Unsplash portraits (rendered in color) use fictional display names, not identification of the pictured people:
  - https://images.unsplash.com/photo-1506794778202-cad84cf45f1d
  - https://images.unsplash.com/photo-1534528741775-53994a69daeb
  - https://images.unsplash.com/photo-1500648767791-00dcc994a43e

Unused legacy artwork has been removed. Replace demonstration portraits with user-approved images before real deployment. All active fonts/icons/photos are bundled, with no runtime asset CDN dependency.

The canonical demo profile uses `assets/avatars/aarav.jpg`. The demo name/ID remain Ishaan Mehta / `demo_ishaan`; the image filename is an asset choice, not an identity claim.
