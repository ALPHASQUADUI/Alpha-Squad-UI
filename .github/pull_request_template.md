## Summary

Describe the change and the user-facing reason for it.

## Module

- [ ] Core / shared UI
- [ ] Overload
- [ ] Documentation
- [ ] Future module

## Performance checklist

- [ ] Uses events instead of unnecessary high-frequency polling
- [ ] No permanent OnUpdate loop was added without a strong reason
- [ ] Hidden/dormant UI does not keep fast animation callbacks running
- [ ] No unnecessary automatic chat spam was added

## Compatibility checklist

- [ ] Primary action bar tested where relevant
- [ ] Backup action bar tested where relevant
- [ ] Subclassing considered where relevant
- [ ] Existing SavedVariables compatibility considered
- [ ] `CHANGELOG.md` updated for user-facing changes

## Testing

Describe how the change was tested in ESO.
