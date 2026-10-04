# Beat Mitra – Google Play publishing guide

Everything Google asks for, with the answers for Beat Mitra. All files are in
the `store/` folder of the repository.

| Item | Value / file |
|---|---|
| App ID (package) | `com.beatmitra.app` (cannot change after first upload) |
| App name | Beat Mitra: Postman Helper |
| Upload file | `beat-mitra-play.aab` from the latest release on GitHub |
| App icon 512×512 | `store/icon-512.png` |
| Feature graphic 1024×500 | `store/feature-graphic.png` |
| Phone screenshots (1080×1920) | `store/screenshots/en`, `kn`, `hi` |
| Store text | `store/listing/en-US.txt`, `kn-IN.txt`, `hi-IN.txt` |
| Privacy policy URL | https://maheshraikg.github.io/beat-mitra/privacy-policy.html |
| Category | Tools (or Productivity) |
| Price | Free · no ads · no in-app purchases |

## 0. One-time: turn on the privacy policy web page

GitHub repo → **Settings → Pages** → Source: **Deploy from a branch** →
Branch: **main**, folder: **/docs** → **Save**. After 1–2 minutes the page is at
https://maheshraikg.github.io/beat-mitra/privacy-policy.html

## 1. Create the app

Play Console → **Create app**
- App name: `Beat Mitra: Postman Helper`
- Default language: English (United States) – en-US
- App or game: **App** · Free or paid: **Free**
- Tick the declarations → **Create app**

## 2. App signing (do this on the first upload)

Play Console → **Test and release → Setup → App signing**.
Recommended: **use the same key as the GitHub APKs**, so phones that installed
from the direct link can later update from Play (and the other way round):
choose **"Use a different key" → "Export and upload a key from Java keystore"**
and follow Google's PEPK steps with:
- keystore: `android/app/release.p12` (from the GitHub repo)
- alias: `beatmitra`
- password: the signing password saved in your Drive folder

If you simply let Google create a new key instead, it also works, but a phone
must uninstall the GitHub version once before installing from Play (data would
be lost unless backed up first).

## 3. Upload the bundle

**Test and release → Production** (or start with **Internal testing**) →
**Create new release** → upload `beat-mitra-play.aab` from the latest GitHub
release → release name e.g. `1.0.6` → release notes (English):
`First release: find addresses, plan routes, record deliveries, record and follow routes. Works offline.`

## 4. Store listing (Grow → Store presence → Main store listing)

- Short and full description: copy from `store/listing/en-US.txt`
- Add translations: **Manage translations → Add your own** → Kannada (kn-IN) and
  Hindi (hi-IN), copy from the other two files
- App icon, feature graphic, phone screenshots: from the table above (upload
  the `en` screenshots for English, `kn` for Kannada, `hi` for Hindi)
- Contact email: your support email · Website: https://maheshraikg.github.io/beat-mitra/

## 5. App content (Policy → App content)

**Privacy policy:** the URL above.

**App access:** "All functionality is available without special access".
Note for reviewers: *"No account or login. On first start the app asks the user
to create their own 4-digit PIN; any PIN works."*

**Ads:** No, the app does not contain ads.

**Content rating:** questionnaire → category **Utility, Productivity,
Communication or Other** → answer **No** to everything (no violence, sexual
content, gambling, user-to-user chat, location sharing with others, etc.).
Result: Everyone / 3+.

**Target audience:** 18 and over (it is a work tool). Not appealing to children.

**News app:** No. **COVID-19 app:** No. **Government app:** **No** – it is an
independent tool, not made by or for a government body (the listing and the app
say "Not an official Department of Posts app").

**Financial features:** None.

**Health:** None.

**Data safety** – the key point is that **no data leaves the device**, so
nothing is "collected" in Google's meaning (collected = sent off the device):
- Does your app collect or share any of the required user data types? **No.**
- (Google may then ask about security practices: data is encrypted on the
  device; users can delete all data in Settings → "Delete all data".)
- Explanation if asked: *"All data (names, addresses, photos, location, delivery
  records) is stored only on the device in an encrypted database. The app has no
  INTERNET permission and no server. Data leaves the device only when the user
  explicitly exports an encrypted file or shares text."*

**Foreground service declaration** (Policy → App content → Foreground service
permissions): type **Location**.
- Use: *"Recording the postman's walking route during deliveries so that a
  relief postman can later follow the same path and return to the post office.
  Recording is started by the user (or when the user starts a delivery run),
  shows an ongoing notification, and stops when the user taps Stop & save."*
- Google asks for a **short video** (YouTube unlisted link is fine) showing:
  start delivery / start recording → the notification appears → screen off and
  walk → stop & save → the saved route on screen. Record it with your phone's
  screen recorder (20–40 seconds).

**Location permission:** the app uses only "while in use" location (no
background-location permission), so no extra location declaration is needed.

## 6. Countries and release

**Production → Countries/regions:** India (add others if you like) →
**Review release → Start rollout**. Business accounts do not need the 14-day
closed test; the first review usually takes a few days.

## Updating later

Every push to `main` builds a new signed release `v1.0.N` with a new
`beat-mitra-play.aab`. Upload that file as a new Production release.
