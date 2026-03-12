# Google Play Image Requirements

Image specifications for each type supported by `gpc listings images upload`.

## Image types

| Type | Flag value | Min size | Max size | Max count | Format |
|------|-----------|----------|----------|-----------|--------|
| Phone screenshots | `phoneScreenshots` | 320×320 | 3840×3840 | 8 | PNG, JPEG |
| 7" tablet screenshots | `sevenInchScreenshots` | 320×320 | 3840×3840 | 8 | PNG, JPEG |
| 10" tablet screenshots | `tenInchScreenshots` | 320×320 | 3840×3840 | 8 | PNG, JPEG |
| TV screenshots | `tvScreenshots` | 1280×720 | 3840×3840 | 8 | PNG, JPEG |
| Wear screenshots | `wearScreenshots` | 320×320 | 3840×3840 | 8 | PNG, JPEG |
| App icon | `icon` | 512×512 | 512×512 | 1 | PNG (32-bit, alpha) |
| Feature graphic | `featureGraphic` | 1024×500 | 1024×500 | 1 | PNG, JPEG |
| TV banner | `tvBanner` | 1280×720 | 1280×720 | 1 | PNG, JPEG |

## Screenshot aspect ratio

- Minimum: 1:2 (portrait) or 2:1 (landscape)
- Maximum: 2:1 (portrait) or 1:2 (landscape)
- Screenshots must not have alpha/transparency

## File size limits

- Maximum file size per image: **15 MB**
- Recommended: optimize PNGs under 5 MB for faster uploads

## Commands

```bash
# List existing images
gpc listings images list --lang en-US --type phoneScreenshots

# Upload a single image
gpc listings images upload --lang en-US --type phoneScreenshots screenshot1.png

# Upload multiple images
gpc listings images upload --lang en-US --type phoneScreenshots \
  screenshot1.png screenshot2.png screenshot3.png

# Delete all images of a type
gpc listings images delete --lang en-US --type phoneScreenshots

# Delete a specific image by ID
gpc listings images delete --lang en-US --type phoneScreenshots --id <image-id>
```

## Best practices

- Upload phone screenshots first — they're the most visible in the Play Store
- Use consistent dimensions across all screenshots in a set
- Feature graphic is required for apps featured by Google
- TV banner is required for Android TV apps
- Optimize file sizes — large files slow down CI uploads
