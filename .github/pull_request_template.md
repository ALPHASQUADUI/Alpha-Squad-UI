## Summary

Describe the change and the user-facing reason for it.

## Module

- [ ] Core / shared UI
- [ ] Overload
- [ ] ULT Tracker
- [ ] Group Ultimate Tracker
- [ ] Documentation / CI
- [ ] Other future module

## Performance checklist

- [ ] Uses events instead of unnecessary high-frequency polling
- [ ] No permanent fast update loop was added without a strong reason
- [ ] Hidden/dormant UI does not keep fast animation callbacks running
- [ ] Reuses controls rather than rebuilding combat UI unnecessarily
- [ ] No unnecessary automatic chat spam was added

## Compatibility checklist

- [ ] Primary action bar tested where relevant
- [ ] Backup action bar tested where relevant
- [ ] Subclassing considered where relevant
- [ ] Existing SavedVariables compatibility considered
- [ ] Optional libraries fail gracefully
- [ ] `CHANGELOG.md` updated for user-facing changes

## Testing

Describe the ESO scenarios tested and attach any relevant errors/screenshots.
