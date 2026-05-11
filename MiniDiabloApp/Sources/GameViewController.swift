import SpriteKit
import UIKit

final class GameViewController: UIViewController {
    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else {
            return
        }

        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
