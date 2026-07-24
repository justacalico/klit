# Changelog

# 11.0.0 (Unreleased)
- Sped up Popular and Hot pages by using the dedicated `/popular.json` API endpoint for day/week/month scales instead of the general `/posts.json` with date tag queries
- Fixed the app flashing/reloading when switching accounts by keeping previous content visible during re-activation ([!19](https://gitlab.com/Openlyst/klit/-/merge_requests/19))
- Fixed check-for-update failing after the app slug changed from `klit` to `kilt` on the Openlyst API ([!18](https://gitlab.com/Openlyst/klit/-/merge_requests/18))
- Moved sidebar Klit branding box down to stop it clashing with the nav buttons ([!17](https://gitlab.com/Openlyst/klit/-/merge_requests/17))

# 10.2.0
- Fixed crash when playing video in release builds on macOS by disabling hardware acceleration
- Fixed artist names not showing on posts by adding `mode=extended` to e621 v2 API requests
- Fixed macOS app icon not displaying by regenerating it via `flutter_launcher_icons`

# 10.1.0
- Migrated to e621 Post API v2
- Updated post response parsing for new JSON structure (files, stats, flags, has, relationships)
- Added support for new fields: uploader_name, change_seq, approver_id, locked_tags
- Tags are now returned as flat array (grouped as 'general' for compatibility)
- Removed unwrapRailsArray from post endpoints (v2 returns arrays directly)

# 10.0.0
- Updated Description
- Bumbed version to 10.0.0
- Fixed video continuing to play when navigating away from a post in the detailed view
- Fixed duplicate window controls on macOS (native traffic lights overlapping with custom title bar buttons)

# 9.0.2
- Fix macos network in debug mode

# 9.0.1
- Fix macos network

# 9.0.0
## Remake
- Remake the whole app.

# 8.1.0

- Remove Server Configuration from Settings: the host/API server is no longer configurable in Settings; to use a different host (e.g. e621 vs e926), add a new account for that host and switch accounts
- Keep tab pages alive with IndexedStack so switching tabs or resizing desktop/mobile does not dispose pages; images and scroll position are preserved
- Search page: when opened with a new query (e.g. from tag tap), update search field and run search via didUpdateWidget
- Optimistic favorite and upvote in post detail: UI and confetti update immediately; API runs in background and state reverts on failure
- Posts provider: use separate loading-more flags for latest/hot/popular so existing lists show without a full loading state when loading more
- Profile: in-memory cache so returning to a previously loaded profile shows instantly, then refreshes in background
- Post card: stable cacheKey for CachedNetworkImage so cache lookup is consistent across rebuilds
- Feeds (edit): tag suggestions in And/Or/Exclude fields via shared TagSuggestionField widget; reuses search-tag logic (debounce, prefix, insert at cursor)
- Post detail: catch precache image failures (invalid image data) so they do not throw or spam the console
- Post detail: full OLED theme support — scaffold, nav bar, desktop top bar, info panel, controller hints and comments sheet use pure black / OLED colors when OLED mode is on
- Settings > Video: add "Autoplay GIFs" (default on) to animate GIFs in home, search, and other grids; when off, post cards show static preview for GIFs
- GIF autoplay: only animate GIFs when the post card is in view (visibility detector); off-screen cards show static preview to reduce lag. While the GIF loads or on error, show the static preview so there is no black or grey flash
- Feeds: when creating or editing a feed you can set rating (All / Safe / Q / E) and sort (Newest, Oldest, Score, Favorites); opening a feed applies these filters like on the search page
- Feeds: optional "Exclude my favorites" (default off); when on, the feed excludes posts you have favorited
- Feeds: subfeeds — attach optional subfeeds to a feed (name + extra include/exclude tags); when viewing the feed, tabs show Main and each subfeed; only one subfeed active at a time; subfeed adds its tags to the main query
- Feeds tab: subfeeds listed under each feed card (indented, smaller) so you can open a feed with a specific subfeed active directly from the list
- Feeds and Search stay inside the shell: opening a feed switches to the Search tab with filters instead of pushing a full-screen route; creating/editing a feed shows the form in the Feeds tab so the nav bar and sidebar remain visible
- Search page: single top bar with search field and filter/search buttons instead of separate title bar and toolbar
- Search page (desktop): hide history sidebar when history is off or empty; results use full width
- OLED mode: glass header variant (search/feed top bar) uses solid black when OLED is on; search toolbar text field uses OLED secondary background
- Settings: full OLED theming — account/cards, sidebar, content header border, category list, nav order and proxy dialogs, update check dialogs use black/secondary OLED colors when OLED mode is on

# 8.0.1

- top bar refactor

# 8.0.0

- README: expanded with features, prerequisites, getting started, and build instructions
- Settings Account: visual refresh — larger avatar with ring, clearer typography, refined cards and spacing; Accounts section with description and filled Add button; account list cards with subtler active state and cleaner Active badge
- Settings Account (mobile): fix semantics assertion (parentDataDirty) by giving embedded account list bounded height (host settings, login, blacklist, settings, toolbar, sidebar, nav bar More menu, search, account management, post detail, loading shimmer)
- OLED theme: use pure black for all backgrounds and bar (was grey secondary/separator)
- Android: opt out of edge-to-edge so status bar can be hidden on Android 15+; re-apply hide after first frame so it sticks
- Fix black-on-black text in Settings Account, Feeds, Profile, Favorites, and Blacklist empty states and help text (use theme-aware label/secondaryLabel on dark/OLED)
- Android: hide system status bar (time, battery, network) for a cleaner full-screen look
- Settings (Android): system back button now returns to the main settings list from sub-pages (e.g. Account) instead of exiting Settings
- Post detail: show instantly when opened from list (Home, Hot, Popular, Search, Feeds, Favorites, Profile) using already-loaded post data; no loading spinner for current post
- Liquid glass: remove purple glow and tint from mobile nav bar (neutral shadow and border only)
- Feed edit: redesigned New feed tab with section cards; Sources show which account is used per host (username or Guest); form spans full width with reduced padding; Sources text easier to read (larger, higher contrast in dark mode)
- Feeds: multi-host support — choose multiple hosts per feed (e.g. e926, e621, e6ai); results merged by date; feed list is global (same for all accounts)
- Feeds: post detail and comments use correct host and account per post (vote, favorite, comment)
- Post detail: preload comments when a post loads; comments sheet shows them immediately and lazy-loads more pages on scroll
- Post detail: use full-screen loading page again while post loads (revert in-content placeholders)
- Post detail: remove refresh button from nav bar (more-options ellipsis only in trailing)
- Search page when opened as route: remove duplicate top nav bar so only the search toolbar (with back button) is shown and the search bar is not hidden
- Post detail: vote buttons and score/comment indicators use thumbs up / thumbs down icons instead of arrows
- Post detail: show initial UI (toolbar + layout) first with in-content placeholders while loading; no full-screen loading screen
- Post grid: cache dimensions from post preview aspect ratio so thumbnails are not stretched or squashed
- Post grid: wrap each cell in AspectRatio to avoid parentDataDirty semantics assertion when scrolling
- Post grid: lighter placeholder (solid grey) for grid cards so scores show fast; images fade in (150ms) as they load
- Post grid: placeholder and error state use theme background (dark / OLED / light) instead of white when no image is loaded
- Sidebar: collapsed state shows only icon for collapse button to fix right overflow
- Performance: offload API JSON parsing to background isolate (compute); blacklist filtering runs on main isolate to avoid isolate transfer issues so infinite scroll and load-more work reliably
- Performance: posts grid uses cacheExtent and passes theme/style into post cards to avoid per-card provider watches; grid thumbnails use memCacheWidth/Height for faster decode
- Performance: storage (accounts, feeds, search history) JSON decode moved to background isolate; blacklist settings text input debounced; I-finished gallery batches setState
- Performance: video thumbnails use CachedNetworkImage; post card liquid-glass shadows reduced from 4 to 2 for less GPU work
- macOS: minimum deployment target raised to 11.0 (required by connectivity_plus and other plugins)
- Post detail: tag chips coloured by tag category (character/species/general/artist/etc.) instead of post rating
- Post detail: preload preview and full image for adjacent posts (±3) so swiping shows images from cache
- "I finished" milk animation: sticky splatter shoots at screen from center-bottom, holds ~5s then fades
- "I finished" milk animation: stringy viscous strands (curved, teardrop, pinched), glossy highlights, subtle wobble during hold
- "I finished" milk animation: spread-out fan (center stream + many streams arcing left/right)
- "I finished" milk animation: strands from separate origins (not one nozzle), sticky center blob, scattered droplets
- Settings Behavior: Gallery button for finished posts — swipe through all I-finished images (camera photo or post image)
- App starts in guest mode (main screen); login page only when user chooses to log in
- Mobile nav bar: default reduced to Home, Search, Profile, Settings; added horizontal padding and spacing; labels shown when &lt;5 items
- Mobile nav bar: "More" (⋯) menu opens Hot, Popular, Favorites, Feeds (and Settings for guests); default bar includes More
- Post detail: preload up to 3 posts on each side of current so swiping doesn't wait for load
- Profile: three tabs (Main, Uploads, Favorites) with pill-style tab bar; all three styled as buttons (subtle bg when unselected); Main shows overview, Uploads/Favorites show post grids
- Search history and feeds are per-account; switching accounts shows only that account's data
- Feeds: add "Both" type option so a feed can show both images and videos (Image / Video / Both)
- Feeds: add And tags (all required) and Or tags (any of); rename include to And, add Or tags field and exclude hint; feed cards show or tags
- Post detail (mobile): use single Download in more-options sheet; remove Download from action icon row
- Post detail: action button labels (Downvote, Download, etc.) stay on one line with ellipsis instead of wrapping
- Settings: fix mobile flash of wrong category when opening with initialCategory (defer content one frame, show placeholder until ready)
- Settings (mobile): fix sub-pages opening wrong category for a split second — set category and show sub-page in one setState
- Settings: show Back button when opened as a route (e.g. from Profile) so user is not stuck; mobile bar and desktop sidebar
- Settings: reorder categories (Network before Data); add Feeds to desktop sidebar order; add Mobile nav bar order to Customization
- Account options: add "Test connection" to verify credentials (mobile action sheet and desktop dialog)
- Account remove: capture AuthProvider and Navigator before showing dialog to fix deactivated widget error when tapping Remove
- Account management moved into Settings > Account only; standalone Accounts route removed; Profile "Manage Accounts" / gear opens Settings on Account
- Profile: remove "Manage Accounts" button from actions card (account settings still via toolbar gear)
- Settings Account: single "Add" button in header only (removed duplicate "Add account" row above list)
- Settings Behavior: grey out "Ask for photo when marking I finished" on desktop and web (camera unavailable)
- Settings Behavior: wrap Finished posts list in Material so InkWell has required ancestor (fix No Material widget found)
- "I finished" on desktop: camera disabled; adds without photo so it works without permission_handler
- Optional "I finished" button (default off) with milk-style animation and optional camera photo; track finished posts and photos in Settings > Behavior
- Code: fix empty catch comment, unnecessary_underscores, and redundant import; clean analyze
- Mobile nav: when 6+ items show icon-only compact bar (less height, no labels); re-add Settings to default navbar; fix Profile/Favorites/Feeds taps; remove Favorites from default navbar
- Feeds: migrate legacy mobile nav order so Feeds appears in navbar for existing users
- Feeds: use e621 file-type metatags ( ~type:jpg ~type:png ~type:gif ~type:webp ) for image and ( ~type:mp4 ~type:webm ) for video so API returns results
- Feed view: opening a feed shows a toolbar with back button and feed name so you can exit the feed; results only below
- Feeds: create image or video feeds with include/exclude tags; open a feed to browse matching posts in search
- Feeds: added to default mobile bottom nav bar
- Post detail: "View profile" opens the in-app profile page for that user instead of an external URL
- Post detail: resolve uploader username by ID when API omits it; show name and PFP after fetch
- Search (mobile): hide history sidebar and show full-width results; filters in bottom sheet instead of overlay; tag suggestions full width
- Settings (mobile): iOS-style main list with search and sub-pages per category; back button returns to list
- OLED theme: apply pure black and OLED secondary/separator colors across shell, nav bar, sidebar, settings, search, profile, login, post cards, and adaptive containers
- Fix Material style bottom nav bar overflow (increase height to 60px so icon + label fit)
- Profile page redesign: hero card with avatar (image when available), stats grid, account info with dividers, styled action buttons
- Settings Account: avatar glow and border use colors extracted from the profile image
- Mobile nav bar: remove solid background behind the bar so only the rounded pill is visible
- Post detail: tapping a tag navigates to the search tab with that tag (no modal/search route)
- Post detail: show uploader profile picture (avatar) when available; fallback to initial letter
- Settings Account: show user profile picture (avatar) when available from API or avatar post
- Settings UI: mobile pill tabs (purple when selected), section header as card, iOS-style rows; desktop macOS-style sidebar with search and blue selection highlight
- Post detail: preserve current post index when switching mobile ↔ desktop (sync index to shell, push route when going to mobile with overlay, pop when going to desktop)
- Download: Android/iOS save to photo gallery (gal); desktop save to Downloads/openlyst/klit with “Open folder”; mobile action bar includes Download (guests see Download only)
- Comments: show creator avatar (preview image) when API provides creator_avatar_url; fallback to placeholder icon
- Search page (when opened from post detail tag): add nav bar with back button so you can return to post
- Post detail: e621-style DText in descriptions and comments ({{tag}} → tappable tag search, [[wiki]], [b]/[i]/[s]/[u]/[spoiler])
- Post detail: tag chips coloured by post rating (explicit=red, safe=green, questionable=grey; backup/unrated unchanged)
- Post detail: uploader shown as profile card (avatar initial, name, “View profile” link); optional uploader name from API (owner/uploader)
- Post detail (mobile and desktop): description and tags use full-width layout so long text/URLs wrap; BBCode [b]/[i] in descriptions and comments converted to Markdown for bold/italic
- Code cleanup: remove verbose debug logging, trim generic comments, fix empty catch and section banners, format and lint
- Upgraded dependencies: dio to ^5.9.1, video_player to ^2.11.0; replaced discontinued flutter_markdown with flutter_markdown_plus
- Complete UI redo: removed old `lib/ui/` folder and rebuilt responsive UI layer with layout scope, shell (sidebar/nav bar), widgets, and pages
- Added live resize frame (debug mode) for testing responsive layouts without resizing the window
- Extracted PostDetailArguments to `lib/core/types/navigation_args.dart` for shared navigation
- Desktop (1024px breakpoint): sidebar, post detail overlay; mobile: bottom nav bar, push navigation
- Fixed post detail overlay state: current post index is synced to shell so switching desktop/mobile preserves which post you were viewing
- Unified all pages to single file pattern with state preservation - pages no longer lose state when resizing window between desktop/mobile
- Refactored account_management_page.dart to unified pattern (removed separate desktop/mobile build methods)
- Added KeyedSubtree wrappers to all pages to preserve state across layout mode changes
- Fixed large posts (e.g. 2048×2048 video) not loading on mobile detail view; constrained video with AspectRatio and RepaintBoundary to avoid parentDataDirty assertion
- Fixed post image layout when switching posts on mobile (image no longer appears small in corner)
- New unified UI system (single codebase for desktop and mobile)
- Fixed scaling/stretching artifact when resizing the app window
- Major performance optimizations: removed continuous background animations, single-page nav (saves RAM/CPU), reduced BackdropFilter blur, RepaintBoundary isolation, default Material UI style
- Stateless
- New navbar engine
- Switch form layouts with loseing data

# 7.0.0

- Updates version to **7.0.0**.
- Updated description to "E926 API client"

## Added

### Pull-to-Refresh on Mobile Home Page
- Added native pull-down-to-refresh support on the mobile Home page
- Swipe down from the top of the post grid to refresh latest posts
- Smooth refresh indicator animation with haptic feedback

### Keyboard Controls for Mobile Post Viewer
Added keyboard navigation support to the mobile post detail viewer, matching the desktop experience:

**Navigation:**
- `A` / `←` — Previous post
- `D` / `→` — Next post

**Actions:**
- `F` — Toggle favorite
- `W` / `↑` — Upvote (toggle)
- `S` / `↓` — Downvote (toggle)

### Material Style Navigation Bar
- Added a proper Material-style bottom navigation bar when Material UI mode is enabled
- Full-width design with simple icon/label layout (no floating pill style)
- Clean top border separator instead of shadow/blur effects
- Consistent with Android Material Design guidelines

### Material Style Settings Page
- Settings page now responds to UI style mode
- Material mode uses solid containers without blur effects
- Clean borders and simple dividers in Material mode
- Removes glass effects and shadows for better performance on lower-end devices

### Rating Aura on Post Cards
- Posts now display a colored glow/aura around the card based on content rating
- **Green** — Safe content
- **Orange** — Questionable content
- **Red** — Explicit content
- Removed the text badge from the bottom-left corner for a cleaner look
- Rating is now instantly visible at a glance without reading text
- **Liquid Glass mode**: layered glows and highlight reflection
- **Material mode**: simple, performance-focused aura

### Centralized Post Grid Settings
- New **POST GRID** section in Settings with comprehensive controls:
  - **Auto Mode** — Automatically adjusts grid columns based on screen width (2 cols for phones, 3 for tablets, up to 8 for large monitors)
  - **Grid Size** — Manual control for number of columns (disabled when Auto Mode is on)
  - **Spacing** — Slider to control gap between post cards (0-16pt)
  - **Padding** — Slider to control outer padding around the grid (0-24pt)
  - **Score Threshold** — Configurable minimum score filter for latest posts (0-100, default: 20). Posts automatically reload when changed.
- Added same POST GRID settings to desktop settings page (Content section)
- Removed per-page grid size controls from Home, Hot, Popular, Favorites, and Search pages
- Removed grid size selectors from desktop toolbar (Home, Hot, Popular, Favorites, Search)
- All pages now use centralized settings for consistent appearance

### Blacklist Management
- New **BLACKLIST** section in Settings (mobile and desktop):
  - **Enable Blacklist** — Toggle to enable/disable blacklist filtering globally
  - **Manage Blacklist** — Opens dedicated page to edit blacklist rules
- **Blacklist Settings Page** with full management:
  - **Sync from Account** — Pull blacklisted tags from your e621/e926 account
  - **Text Editor** — Edit blacklist entries directly (one tag/rule per line)
  - **Help Dialog** — Documents blacklist syntax (AND logic, rating filters, wildcards, metatags)
  - Shows active rule count and enabled status
- All pages automatically filter posts based on blacklist rules

## Fixed

### Left-Handed Mode Confetti Position
- Fixed confetti animation playing from the wrong side when left-handed mode is enabled
- Confetti now correctly originates near the favorite button position in both left and right-handed modes

### Auto Mode Grid Scaling
- Fixed auto mode only using up to 4 columns even on large screens
- Auto mode now scales properly: 2 cols (phones) → 3 (tablets) → 4-5 (small desktops) → 6-8 (large monitors)
- Grid now properly responds to window resizing using LayoutBuilder

### Tag Suggestions Overhaul
- **Fixed `-tag` and `~tag` prefix handling**: Tag suggestions now properly work when typing exclusion tags (e.g., `-scat`, `-young`) or optional tags (`~tag`)
- **Fixed suggestions closing unexpectedly**: Removed aggressive focus-based closing that caused suggestions to disappear while typing
- **Fixed suggestions appearing when not wanted**: Suggestions now only appear when actively typing a tag (2+ characters)
- **Tap outside to close**: Suggestions close when tapping anywhere outside the suggestion list
- **Better word detection**: Properly extracts the current word being typed, handling cursor position correctly
- **Prefix preservation**: When selecting a suggestion for `-tag` or `~tag`, the prefix is correctly preserved

### Full Resolution Image Loading
- Fixed mobile post viewer not loading full resolution images
- Mobile now uses the same resolution priority as desktop: full file → sample → preview
- Fixes issues with small images (e.g. 512x512) not displaying at full quality on alternative servers

# 6.0.0

## Added

### Gamepad & Controller Support (Desktop)
Full gamepad/controller support for desktop UI — SteamOS and Steam Deck compatible.

**Post Detail View Controls:**
- `LB` / `RB` — Navigate between posts
- `A` — Toggle fullscreen
- `B` — Close/go back
- `Y` — Toggle favorite
- `RT` — Upvote
- `X` — Downvote
- Thumbstick / D-pad — Sidebar menu navigation
- Visual button hints overlay when controller is connected
- Haptic feedback for all actions

**Login Screen Controls:**
- D-pad — Navigate between form fields and buttons
- `A` — Select/activate focused item
- `Y` — Quick guest login
- `X` — Toggle custom host
- Visual focus indicators on all interactive elements

**New Input System:**
- `GamepadController` service for centralized input handling
- `GamepadInputMixin` for easy widget integration

### Desktop Download Functionality
- Download posts directly from the detail view
- Files saved to user's Downloads folder with progress indicator
- Confirmation dialog with option to open folder
- Automatic detection of existing files

### Live Responsive UI
- Automatic switching between mobile and desktop layouts on window resize
- Post detail, search, favorites, and profile pages all support live layout switching
- Threshold: Desktop UI at ≥1024px width, Mobile UI below

### Shared Navigation State
- Current page preserved when resizing between mobile and desktop
- Navigation indices automatically mapped between UI modes

### Video Settings
New video settings section in both mobile and desktop settings:
- **Auto Play** — Control whether videos automatically play when viewing posts
- **Mute by Default** — Start videos muted to avoid unexpected audio
- Settings apply to both inline video player and fullscreen viewer

### Check for Updates
- "Check for Updates" option in About section (mobile and desktop)
- Fetches latest version info via Openlyst API
- Shows current vs latest version comparison
- Direct link to download page when update available
- Glassmorphic dialog design on desktop

### Search History Privacy
- Toggle to disable search history recording (mobile and desktop)
- New "Data" category in desktop settings
- Clear search history button with item count
- When disabled, searches are not saved to history

---

## Changed

### Dependency Updates
| Package | From | To |
|---------|------|-----|
| dio | ^5.4.0 | ^5.9.0 |
| flutter_secure_storage | ^9.2.2 | ^10.0.0 |
| provider | ^6.1.2 | ^6.1.5+1 |
| shared_preferences | ^2.2.3 | ^2.5.4 |
| connectivity_plus | ^6.0.3 | ^7.0.0 |
| video_player | ^2.8.0 | ^2.10.1 |
| chewie | ^1.8.0 | ^1.13.0 |
| media_kit | ^1.2.3 | ^1.2.6 |
| url_launcher | ^6.2.5 | ^6.3.2 |
| flutter_launcher_icons | ^0.14.3 | ^0.14.4 |

### UI Improvements

**Sidebar Collapse Button:**
- Animated icon rotation when toggling
- "Collapse" label with chevron indicator in expanded mode
- Tooltip for better accessibility
- Enhanced hover effects with purple gradient and shadow
- Better visual consistency in both states

**Desktop Time Range Selector (Hot & Popular Pages):**
- Modern glassmorphic design with purple/indigo gradient theme
- Hover effects on time range options (Today, This Week, This Month)
- Sleek calendar button with divider separator
- Desktop-optimized date picker dialog with gradient styling
- Enhanced "Done" button with purple gradient
- Full date format (MMM d, yyyy) for custom date selection

**Account Management Page:**
- Responsive layout adapting to desktop and mobile
- Glassmorphic design with backdrop blur effects on desktop
- Gradient header with stylish back button
- Improved account cards with hover effects and gradient active state
- Desktop-optimized modal dialogs
- Consistent purple/indigo gradient theme

---

## Fixed

- Fixed `use_build_context_synchronously` warnings in account management page by adding proper mounted checks after async operations
- Fixed tag suggestion popup not closing when clicking search button with meta tags (e.g., "video")
- Fixed tag suggestions appearing when search field is not focused
- Tag suggestion overlay now properly checks focus state before displaying
- Cancels pending tag fetch requests when searching to prevent race conditions

---

## Removed

### List View Option
Removed list view from the entire app:
- Home, Hot, Popular, and Search pages now use grid view only
- Removed grid/list toggle button from toolbars
- Removed `PostsList` widget
- Removed `ViewToggleButton` widget
- Removed `PostListShimmer` widget

# 5.0.0

- Fixed account manager not working.
- Reload all data when switching accounts.
- Fixed some platforms not having icons.

# 4.0.0

- Bumped version to **4.0.0**.
- Updated description to "Advanced E926 client"
- Dont show profile button if in guest mode.
- Center selectors.
- Fixed GIFs not playing.
- Dont show post actions for guest users.
- Load the next page of posts before hits the bottom.
- Support for custom date ranges.
- Fixed finished guest accounts able to countiune to use the app, navigate back to the login screen.
- Updated the Server Managment screen UI.
- Reload post data when changing a host.
- Fixed logging out of accounts not working.

# 3.1.0
- Add a lightweight theme.
- Fixed desktop video player not updateing on new posts.
- Updated openlyst url.

# 2.1.0
- Added confetti animation when favoriting a post (can be toggled in Settings)
- Added customizable navigation order for mobile navbar and desktop sidebar
- **Completely redesigned the desktop settings page** with a macOS System Preferences-style sidebar navigation and animated transitions
- Fixed AppImage builds failing due to FUSE not being available in Docker CI environments.
- Fixed tag suggestion menu not closing when pressing Enter to search without selecting a suggestion.
- Improved blacklist sync from e621 profile to local settings on profile load.

# 2.0.0
- Adds guest mode.
- Removed e621 as the default host.
- Fixed the keyboard not being able to be reopened in search.
- Fixed tag suggestions not closing.
- Adds keyboard shortcuts for desktop.
- Fixed saving credentials on desktop.
- Updated desktop theme.
- Redesigned the login page.
- Deprecates RawKeyboardListener.
- Updated mobile theme.
- Adds support for a web proxy.
- No longer shows a full-screen button for desktop post views if it's a video.
- Adds support for blocklists.
- Fixed tag suggestion prompt not closesing in some cases.
