import UIKit
import SnapKit
import Firebase
import JTAppleCalendar

class ViewController: UIViewController {
    weak var collectionView: UICollectionView?
    
    var db: Firestore!
    //Quest which parts should be part of the ViewModel
    var tasks = [ToDoItem]()
    
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
        
        // firestore
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        setUpNavBar()
        fetchToDoList()
        
        // Quest: do we need to assign self for all extensions?
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.alwaysBounceVertical = true
        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.register(TaskCell.self, forCellWithReuseIdentifier: "cellId")
        self.collectionView?.register(TaskFooter.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerID")
    }
    
    
    private func setUpNavBar() {
        navigationItem.title = "Simple ToDo List"
               
       let leftButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: nil)
       navigationItem.leftBarButtonItems = [leftButton]
       
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.compose, target: nil, action: nil)
       navigationItem.rightBarButtonItems = [doneButton]
    }
    
    
    func fetchToDoList() {
        db.collection("todoItems").getDocuments() { (snapshot, err) in
            if let err = err  {
                print("Error getting documents: \(err)")
            } else {
                for document in snapshot!.documents {
                    //Quest is this the right way to update the view? because the for loop is bad
                    DispatchQueue.main.async {
                        let data = document.data()
                        let task = ToDoItem(id: document.documentID,
                                            // Quest is this the right way to do it?
                                            text: data["text"] as? String ?? "",
                                            userID: data["userID"] as? String ?? "",
                                            isCompleted: data["isCompleted"] as? Bool ?? false)
                        self.tasks.append(task)
                        self.collectionView?.reloadData()
                    }

                }
            }

        }

    }

    func addTask(taskName: String) {
        let uuid = NSUUID().uuidString
        let newToDoItem = ToDoItem(id: uuid, text: taskName, userID: "userID", isCompleted: false)
        self.tasks.append(newToDoItem)
        self.collectionView?.reloadData()
        
        db.collection("todoItems").document(uuid).setData(newToDoItem.getDict())

    }
    
    //Quest right place to put this? versus UICollectionViewDataSource
    func deleteTask(cell: UICollectionViewCell) {
        if let deletionIndexPath = collectionView?.indexPath(for: cell) {
            let taskToDeleteID = tasks[deletionIndexPath.item].id
            tasks.remove(at: deletionIndexPath.item)
            collectionView?.deleteItems(at: [deletionIndexPath])
            db.collection("todoItems").document(taskToDeleteID).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
        }
    }
    
    func updateCheckbox(cell: UICollectionViewCell, isChecked: Bool) {
        if let indexPath = collectionView?.indexPath(for: cell) {
            var taskToUpdate = tasks[indexPath.item]
            taskToUpdate.isCompleted = !taskToUpdate.isCompleted
            db.collection("todoItems").document(taskToUpdate.id).updateData(["isCompleted": isChecked]){ err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
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
        taskCell.nameLabel.text = tasks[indexPath.item].text
        taskCell.viewController = self
        taskCell.checkMark.isChecked = tasks[indexPath.item].isCompleted
        return taskCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footerID", for: indexPath) as! TaskFooter
        footer.viewController = self
        return footer
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath)
    }
    
    //Quest why is this padding not working?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsetsMake(0,15,0,15)
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
    var viewController: ViewController?
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let checkMark: CheckBox = {
        //checkmark set up
        let checkMark = CheckBox.init()
        checkMark.style = .tick
        checkMark.borderStyle = .rounded
        return checkMark
    }()
    
    override func setupViews() {
        //Quest why so hard to center things? Is this the correct way to add padding "x:15"
        checkMark.frame = CGRect(x:0, y:(self.frame.height - 22)/2, width: 22, height: 22)
        checkMark.addTarget(self, action: #selector(onCheckBoxValueChange(_:)), for: .valueChanged)
        
        //delete icon set up
        let deleteIcon = UIImage(named: "delete")?.withRenderingMode(.alwaysOriginal)
        deleteButton.setImage(deleteIcon, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTask), for: .touchUpInside)

        //Quest is there a better way to add multiple subviews?
        addSubview(checkMark)
        addSubview(nameLabel)
        addSubview(deleteButton)
        NSLayoutConstraint.activate([
            nameLabel.leftAnchor.constraint(equalTo: checkMark.rightAnchor),
            nameLabel.rightAnchor.constraint(equalTo: deleteButton.leftAnchor),
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            deleteButton.rightAnchor.constraint(equalTo: self.rightAnchor),
            deleteButton.topAnchor.constraint(equalTo: self.topAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        //TODO add padding
//        nameLabel = UIEdgeInsetsMake(0, 8, 0, 8)

    }
    
    @objc func deleteTask() {
        viewController?.deleteTask(cell: self)
    }
    
    @objc func onCheckBoxValueChange(_ sender: CheckBox) {
        viewController?.updateCheckbox(cell: self, isChecked: sender.isChecked)
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

