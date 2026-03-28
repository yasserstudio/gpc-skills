# Review Management

## Listing Reviews

```bash
# All recent reviews
gpc reviews list

# Filter by star rating
gpc reviews list --stars 1-2     # 1 and 2 star reviews
gpc reviews list --stars 5       # 5 star reviews only

# Filter by language
gpc reviews list --lang en       # English reviews
gpc reviews list --lang ja       # Japanese reviews

# Filter by time
gpc reviews list --since 7d     # Last 7 days
gpc reviews list --since 30d    # Last 30 days

# Combine filters
gpc reviews list --stars 1-2 --since 7d --lang en

# Pagination
gpc reviews list --limit 50
```

## Viewing a Single Review

```bash
gpc reviews get <review-id>
```

Shows full review text, user info, star rating, and device info.

## Replying to Reviews

```bash
# Inline reply (max 350 characters — validated before sending)
gpc reviews reply <review-id> --text "Thank you for your feedback"
```

### Reply Best Practices

- **Respond within 24 hours** — faster responses lead to higher rating updates
- **Max 350 characters** — GPC validates this before sending
- **Be helpful, not defensive** — acknowledge the issue, offer a solution
- **Don't include personal info** — review replies are public

### Reply Templates

**Bug report:**
```
Thanks for reporting this. We've identified the issue and a fix is coming in the next update. Sorry for the inconvenience.
```

**Feature request:**
```
Great suggestion! We've added this to our roadmap. Stay tuned for updates.
```

**Generic positive:**
```
Thank you for the kind review! We're glad you're enjoying the app.
```

## Exporting Reviews

```bash
# Export to CSV
gpc reviews export --format csv --output reviews.csv

# Export to JSON
gpc reviews export --format json --output reviews.json
```

## Rate Limits

The Reviews API has stricter rate limits than other endpoints:

| Operation | Limit |
|-----------|-------|
| GET (list/get) | 200 requests per hour |
| POST (reply) | 2,000 requests per day |

GPC handles rate limiting automatically with exponential backoff, but be aware of these limits when processing large volumes of reviews.

## Monitoring Reviews in CI

```bash
# Check for new negative reviews in CI
NEW_REVIEWS=$(gpc reviews list --stars 1-2 --since 1d --output json | jq '.data | length')
if [ "$NEW_REVIEWS" -gt 0 ]; then
  echo "Warning: $NEW_REVIEWS new negative reviews in the last 24 hours"
fi
```
