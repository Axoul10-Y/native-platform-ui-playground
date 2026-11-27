# Native Playground για iOS 27

Flutter project με τέσσερα tabs. Το Controls τρέχει σε Flutter και χρησιμοποιεί τα native_platform_ui 0.0.6 και sf_symbols 0.6.1. Μία κοινή UINavigationController και μία UITabBar κρατούν τη native πλοήγηση. Τα demos που χρειάζονται απευθείας πρόσβαση στο λειτουργικό είναι σε UIKit ή SwiftUI.

## Εκτέλεση σε Mac

Χρειάζεσαι Xcode με **iOS 27 SDK** και iPhone ή simulator με iOS 27 ή νεότερο. Το project χρησιμοποιεί Swift Package Manager. Το pubspec και το lockfile έχουν ελεγχθεί με Flutter 3.44.9 και Dart 3.12.2. Άνοιξε πρώτα έναν iOS 27 simulator. Από τον φάκελο του project τρέξε:

    flutter pub get
    flutter devices
    flutter run -d <device-id>

Αντικατάστησε το <device-id> με το αναγνωριστικό που έδειξε το flutter devices. Το flutter run δημιουργεί τα τοπικά αρχεία του Xcode project. Για debug από Xcode άνοιξε το ios/Runner.xcworkspace. Αν επιλέξεις πραγματικό iPhone, όρισε το δικό σου Signing Team στο Runner.

## Δοκίμασε πρώτα

1. **Library → Edit.** Πάτησε το κόκκινο μείον μιας γραμμής και μετά Delete. Σύρε μια άλλη γραμμή από τη λαβή της για αναδιάταξη. Πάτησε Done. Η λίστα αποθηκεύεται στη συσκευή. Με παρατεταμένο πάτημα μπορείς να αλλάξεις ένα favorite.
2. **Library → …** Το menu έχει New Item, Sort by Name, Favorites Only, Restore Examples, Share List και ξεχωριστή destructive ενέργεια Delete All Items με επιβεβαίωση. Το Restore Examples συμπληρώνει όσα παραδείγματα λείπουν.
3. **Library → Controls.** Παρακολούθησε το ίδιο … καθώς προστίθεται το Share στα αριστερά του. Πάτησε Share για το activity sheet. Κλείσε το Group toolbar actions για να μετακινηθεί το Share στο αριστερό άκρο της οθόνης. Το ίδιο menu παραμένει στα δεξιά.
4. **Controls → Text & Values.** Δοκίμασε push και swipe-back με το ίδιο menu στη navigation bar. Στο Library, άνοιξε μια γραμμή για να δεις τη μετάβαση στο detail με το Favorite. Τα bar items έχουν σταθερά identifiers για το matching του UIKit. Το λειτουργικό επιλέγει την ακριβή κίνηση για κάθε διάταξη και ρύθμιση προσβασιμότητας.
5. **Catalog → Scrolling Toolbar.** Σύρε τη λίστα προς τα πάνω για να μικρύνει ο μεγάλος τίτλος και γύρισε στην κορυφή για να μεγαλώσει ξανά. Η αρχική επιλογή Never κρατά ορατή την μπάρα. Δοκίμασε Down ή Up για την ελαχιστοποίηση ολόκληρης της μπάρας. Το demo αλλάζει το πραγματικό navigationBarMinimization του iOS 27.
6. **Catalog → Dialogs & Sheets.** Άνοιξε το Rename, το Document actions, το resizable sheet και το popover. Στο sheet σύρε τη λαβή ανάμεσα στα δύο ύψη ή κλείσε το με swipe.
7. **Motion → Glass morph.** Άνοιξε και κλείσε την ομάδα εργαλείων. Στη συνέχεια δοκίμασε αλλαγή συμβόλου, τα τρία springs και το zoom σε πλήρη οθόνη.

## Περιεχόμενα

| Tab | Παραδείγματα |
| --- | --- |
| Library | Native inset-grouped table, Edit/Done, delete, swipe, reorder, pull-to-refresh, favorites, context menu, empty states, detail, προσθήκη με text alert |
| Controls | Οριζόντια και κάθετα linked buttons, native switches, glass container, native menu, SF Symbols, επτά επιλεγόμενα symbol effects, native alert, διαδραστικό tab bar preview |
| Catalog | Native UISlider, stepper, toggle, segmented/menu/wheel pickers, calendar, date/time, color και font pickers, text field, secure field, text editor, button styles και control group |
| Catalog | Progress, spinner, gauge, haptics, disclosure, paging, grid, search με scopes, scroll minimization, photo και document pickers |
| Catalog | Alert με text field, confirmation dialog, popover, medium/large sheet, full-screen cover και share sheet |
| Motion | Liquid Glass morph, symbol replacement, smooth/snappy/bouncy spring, keyframes, matched-source zoom |

## Αρχεία

- lib/main.dart — Flutter controls, package demos και method channel προς το native navigation.
- ios/Runner/SceneDelegate.swift — Flutter engine, plugin registration και window scene.
- ios/Runner/PlaygroundTabs.swift — shared navigation bar, tab selection, menu, share sheet και push.
- ios/Runner/LibraryController.swift — editable table, αποθήκευση και detail.
- ios/Runner/Catalog.swift — controls, pickers, presentations και iOS 27 scrolling toolbar.
- ios/Runner/MotionLab.swift — διαδραστικά παραδείγματα κίνησης.

## Έλεγχοι

Πέρασαν το flutter analyze, το flutter test και η δημιουργία του Flutter asset bundle. Ελέγχθηκαν η σύνταξη Swift και τα αρχεία του Xcode project. Η εκτέλεση στο iOS, η οπτική επιβεβαίωση των morphs και το XCTest για το Edit απαιτούν macOS και Xcode. Στο Xcode το Product → Test εκτελεί το RunnerTests.

## Αναφορές

- [Apple UIKit Catalog](https://developer.apple.com/documentation/uikit/uikit-catalog-creating-and-customizing-views-and-controls)
- [Apple Human Interface Guidelines · Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Apple · Matching bar button items across transitions](https://developer.apple.com/documentation/uikit/uibarbuttonitem/identifier)
- [Apple · Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [Apple · iOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes)
- [native_platform_ui 0.0.6](https://pub.dev/packages/native_platform_ui/versions/0.0.6)
- [sf_symbols 0.6.1](https://pub.dev/packages/sf_symbols/versions/0.6.1)
