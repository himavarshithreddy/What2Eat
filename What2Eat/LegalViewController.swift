import UIKit
import WebKit

class LegalViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    var loadingContainerView: UIView!
    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupActivityIndicator()
        loadLegalContent()
    }
    
    // MARK: - WebView Setup
    private func setupWebView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Activity Indicator Setup with Styling
    private func setupActivityIndicator() {
        // Container view for a nicer look
        loadingContainerView = UIView()
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = false
        loadingContainerView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        loadingContainerView.layer.cornerRadius = 10
        loadingContainerView.clipsToBounds = true
        view.addSubview(loadingContainerView)
        
        // Center the container view in the parent view
        NSLayoutConstraint.activate([
            loadingContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingContainerView.widthAnchor.constraint(equalToConstant: 80),
            loadingContainerView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Activity indicator styling
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white // White on dark background looks crisp
        loadingContainerView.addSubview(activityIndicator)
        
        // Center the activity indicator within its container
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor)
        ])
    }
    
    // MARK: - Load Content
    private func loadLegalContent() {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
        // Show the loading indicator
        loadingContainerView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    // MARK: - WKNavigationDelegate Methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        loadingContainerView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        loadingContainerView.isHidden = true
        print("Failed to load legal content: \(error.localizedDescription)")
    }
}
