# 🔒 CLAWDBOT SECURITY DASHBOARD

## Daily Security Audit

**Status:** ✅ Scheduled (runs daily at 9:00 AM)

**Last Run:** $(date)

**Schedule:** `0 9 * * *` (9 AM daily)

**Next Run:** Tomorrow at 9:00 AM

---

## Quick Actions

### Run Audit Now
```bash
node skills/security-audit/scripts/audit.cjs --full
```

### Auto-Fix Common Issues
```bash
./scripts/security-auto-fix.sh
```

### View Today's Audit Log
```bash
tail -20 logs/security-audit-daily.log
```

### Check Audit Schedule
```bash
launchctl list | grep com.clawd.daily-security-audit
```

---

## Security Status

| Check | Status | Details |
|-------|--------|---------|
| Gateway Bind | ✅ PASS | Loopback only |
| Gateway Auth | ✅ PASS | Token mode |
| Token Strength | ✅ PASS | 40 characters |
| DM Policy | ✅ PASS | Pairing mode |
| Group Policy | ✅ PASS | Allowlist |
| File Permissions | ✅ PASS | 600 (owner only) |
| Secrets in Config | ⚠️ WARN | API keys present |

**Overall Score:** 6/7 PASS, 1 WARN

---

## Alert History

| Date | Critical | High | Action Taken |
|------|----------|------|--------------|
| 2026-01-30 | 0 | 1 | Discord alert sent |

---

## Response Protocol

### When CRITICAL Issues Found:
1. 🚨 Discord alert sent immediately
2. Check `logs/security-audit-latest.json` for details
3. Run: `./scripts/security-auto-fix.sh`
4. If not resolved, escalate to manual review

### When HIGH Issues Found:
1. 🟠 Discord alert sent
2. Review issue in audit log
3. Apply recommended fixes
4. Re-run audit to confirm

### When All Clear:
1. ✅ Logged silently
2. No action needed

---

## Files & Locations

| File | Purpose |
|------|---------|
| `scripts/daily-security-audit.sh` | Daily audit runner |
| `scripts/security-auto-fix.sh` | Auto-fix script |
| `logs/security-audit-daily.log` | Daily audit log |
| `logs/security-audit-latest.json` | Latest full report |
| `logs/security-alerts-sent.log` | Alert history |
| `~/Library/LaunchAgents/com.clawd.daily-security-audit.plist` | Launchd schedule |

---

*Last updated: 2026-01-30*
*Audit job: com.clawd.daily-security-audit*
