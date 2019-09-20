import UIKit
import SnapKit
import Firebase

class ViewController: UIViewController {
    weak var collectionView: UICollectionView?
    var db: Firestore!
    var tasks = [String]()
    
    override func loadView() {
        super.loadView()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        
        self.collectionView = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        firestore
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        setUpNavBar()
//        fetchToDoList()
        
        // Quest: do we need to assign self for all extensions?
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.alwaysBounceVertical = true
        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.register(TaskCell.self, forCellWithReuseIdentifier: "cellId")
        self.collectionView?.register(TaskFooter.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerID")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchToDoList()
    }
    
    private func setUpNavBar() {
        navigationItem.title = "Simple ToDo List"
               
       let leftButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: nil)
       navigationItem.leftBarButtonItems = [leftButton]
       
       let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: nil)
       navigationItem.rightBarButtonItems = [doneButton]
    }
    
    
    func fetchToDoList() {
        db.collection("todoItems").getDocuments() { (snapshot, err) in
            if let err = err  {
                print("Error getting documents: \(err)")
            } else {
                for document in snapshot!.documents {
//                    is this the right way to update the view? because the for loop is bad 
                    DispatchQueue.main.async {
                        self.tasks.append(document.data()["text"] as? String ?? "")
                        self.collectionView?.reloadData()
                    }
                    
                }
            }
            
        }
        
    }
    


    func addTask(taskName: String) {
        tasks.append(taskName)
        collectionView?.reloadData()
        
        var ref: DocumentReference? = nil
        ref = db.collection("todoItems").addDocument(data: [
            "userID": "12345",
            "text": taskName,
 
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }

    }
    
}

//It also handles the creation and configuration of cells and supplementary views used by the collection view to display your data
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let taskCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! TaskCell
        taskCell.nameLabel.text = tasks[indexPath.item]
        return taskCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footerID", for: indexPath) as! TaskFooter
        footer.viewController = self
        return footer
    }
}

// The methods of this UICollectionViewDelegateFlowLayout protocol define the size of items and the spacing between items in the grid.
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
}


// UICollectionViewCell - add tasks footer cell
class TaskFooter: BaseCell {
    
    var viewController: ViewController?
    
    let taskNameTextField: UITextField = {
       let textField = UITextField()
        textField.placeholder = "Enter Task Name"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Task", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func setupViews() {
        addSubview(taskNameTextField)
        addSubview(addTaskButton)
        
        addTaskButton.addTarget(self, action: #selector(addTask), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            taskNameTextField.leftAnchor.constraint(equalTo: self.leftAnchor),
            taskNameTextField.topAnchor.constraint(equalTo: self.topAnchor),
            taskNameTextField.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            addTaskButton.leftAnchor.constraint(equalTo: taskNameTextField.rightAnchor),
            addTaskButton.topAnchor.constraint(equalTo: self.topAnchor),
            addTaskButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        //TODO add padding
//        nameLabel = UIEdgeInsetsMake(0, 8, 0, 8)

    }
    
    @objc
    func addTask() {
        viewController?.addTask(taskName: taskNameTextField.text!)
        taskNameTextField.text = ""
    }
}

// UICollectionViewCell - task cells
class TaskCell: BaseCell {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func setupViews() {
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            nameLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        //TODO add padding
//        nameLabel = UIEdgeInsetsMake(0, 8, 0, 8)

    }
}

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
    }
}

// Create an extension to handle graphics
extension ViewController {
    func setUpTableView() {
        let tableView = UITableView()
        tableView.separatorInset = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
    }
    
    
}
