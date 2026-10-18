# F6: phone resilience

What the app does on a slow, flaky or sleeping-server network, and how to check it on a real phone.

## What changed

| Area | Before | Now |
|---|---|---|
| Connections | A new HTTP client for every call (a new TLS handshake each time) | One shared client (`HttpTransport`), one connection reused |
| Timeouts | One 60 s wait that only stopped waiting; the socket stayed open | Per-attempt timeout that aborts the request: reads 30 s, writes 45 s, photo upload 90 s |
| Retry | None | **GET only**, at most 3 attempts inside 75 s, jittered backoff, honours `Retry-After` (max 10 s). Retried: connection failures, timeouts, 408, 429, 502, 503, 504. Never retried: POST, PATCH, DELETE, payment status (the poller owns that schedule) |
| Sleeping server | A silent spinner | After 5 s of waiting a banner says "Waking the server, this can take a minute" |
| Token refresh | Every 401 refreshed on its own; a network error during refresh logged the person out | One refresh at a time (single flight); a network error keeps the session; only a refresh the server rejects ends it |
| Log Out | Cleared tokens locally | Clears tokens and the payment note, tells the server (best effort, never blocks) |
| Offline | Error screen | Hostel list, cities and localities fall back to the last good copy (max 12 entries, 7 days, 60 KB each) with a "No connection. Showing hostels saved 3 hours ago" line and Retry. Only connection problems use the copy; a server error is shown as an error. Nothing personal is ever cached |
| Filter chips | Every chip refetched and blanked the list | Non-AC and Premium filter the loaded pages locally; Boys, Girls, AC refetch but keep the old list visible meanwhile |
| Pictures | Decoded at full size | Decoded at the size drawn (`cacheWidth`), list covers at most 720 px |
| Assets | 4 unused or duplicate pictures | Removed (`images/` 7.9 MB to 4.7 MB) |
| Card entrance | `100 ms * index` delay (index 30 waited 3 s) | `60 ms * min(index, 6)` |
| Payment waiting | Timer every 2.5 s (requests could pile up), gave up at 75 s, Try Again closed the screen and created a new order | One question at a time, a 75 s time budget, Try Again asks the server first |
| Payment memory | Payment id lived only in screen state | Written to phone storage (ids only) before leaving for the UPI app or card sheet; home shows "A payment is waiting to be confirmed" with Check |
| Card pay | A lost verify answer was shown as failure | Goes to the status screen, which asks the server (the Razorpay webhook also confirms it) |

## Payment rules the app now follows

1. The server is the only judge. SUCCESS, FAILED and REFUNDED end the wait; anything else (including "could not reach the server") is "still waiting", never "failed".
2. A new order is created only after the server said FAILED for the old payment, or when the booking has no payment note.
3. Opening the payment screen for a booking that has a payment note first asks the server about that payment.
4. The note holds ids and a timestamp only, expires after 24 hours, and is cleared on SUCCESS, FAILED, card cancel/decline and Log Out.

## Pointing a build at staging

```
flutter run --dart-define=API_BASE_URL=https://hostel-hunt-admin-pannel.onrender.com/api/v1
```

## Device test script (about 20 minutes, one Android phone)

Use a build pointed at staging. Staging has no data until the seed runs; steps marked (needs seed) wait for it.

**A. Sleeping server**
1. Leave staging idle for 20 minutes so Render sleeps.
2. Open the app. Expected: within about 5 s a dark pill "Waking the server, this can take a minute" appears at the top; the hostel list (or an error with Retry) appears within about a minute; the pill disappears when the answer arrives.

**B. Offline copy**
1. With the network on, open the home screen until hostels show (needs seed).
2. Turn on airplane mode, kill the app, reopen it.
3. Expected: hostels still show with "No connection. Showing hostels saved ... ago." and a Retry button. Turn the network back on, tap Retry: the line disappears.
4. Open Search or a hostel you did not open before while offline: an error with a retry, not a blank screen.

**C. Chips**
1. Tap Non-AC, then Premium, then All: the list changes instantly, no spinner, no blank list.
2. Tap Boys: the old list stays visible while the new one loads.

**D. Slow network**
1. Use a throttled connection (phone developer option, or move away from the router). Scroll the home list quickly.
2. Expected: no freeze while pictures load; memory stays flat (Android Studio Profiler or `adb shell dumpsys meminfo <package>`).

**E. Payment survives the app being killed (needs seed, Razorpay TEST keys, see `backend/docs/PAYMENT_TEST.md`)**
1. Book a bed, choose a UPI app, tap Pay Now. In the UPI app do NOT finish.
2. Swipe Hostel Hunt away from recent apps (kills it). Reopen the app.
3. Expected: home shows "A payment is waiting to be confirmed." Tap Check: "Waiting for your payment to confirm..." then, after the budget, "Still Waiting" with Check Again and Check later.
4. Tap Check Again: "The server has not confirmed this payment yet. Please do not pay again". No new order was created (the staging log shows no second `create-order`).
5. Repeat but complete the test payment, kill the app before it returns, reopen, tap Check: success screen, banner gone.
6. Fail the payment on purpose: Check shows "Payment Failed"; Try Again goes back to the payment screen with a fresh order.

**F. Card path**
1. Pay with the Razorpay test card. Turn on airplane mode the instant the card sheet closes (before verify answers).
2. Expected: the status screen, not an error; turn the network back on, Check Again shows success once the webhook or status reports it.

**G. Log Out**
1. With a payment note present (step E1), Log Out. Expected: banner gone after logging back in as someone else.

## Profile-mode numbers for card rendering (not changed yet)

Card blur and shadows are NOT changed in F6. To decide, record these on the phone in profile mode:

```
flutter run --profile --dart-define=API_BASE_URL=<staging url>
```
Open DevTools, Performance, scroll the home list for 20 seconds with 20+ hostels, and note: average and worst frame time (UI and raster), "janky" frame count, and the memory graph. Send the numbers; blur and shadow reductions are decided from them.
