import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Quick UI setup
        setupQuickLaunchContent()

        // Defer heavy initializations
        performDeferredInitializations()

        print("App launched successfully")
        return true
    }

    func setupQuickLaunchContent() {
        // Initialize the window and set a basic view controller if not using Storyboards
        window = UIWindow()
        window?.rootViewController = ViewController() // Adjust ViewController to your actual initial view controller
        window?.makeKeyAndVisible()
    }

    func performDeferredInitializations() {
        DispatchQueue.global(qos: .background).async {
            // Perform heavy tasks here like data preloading or complex setup
        }
    }

    // Handle custom URL scheme redirects
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Ensure the URL scheme matches the expected one
        guard url.scheme == "moodifyapp" else {
            print("Error: Unrecognized URL scheme")
            return false
        }

        // Handle the Spotify redirect
        SpotifyAuthManager.shared.handleRedirect(url: url) { success in
            DispatchQueue.main.async {
                if success {
                    print("Spotify authentication successful!")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginSuccess"), object: nil)
                } else {
                    print("Spotify authentication failed.")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                }
            }
        }

        return true
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // Set a default background color
    }
}
