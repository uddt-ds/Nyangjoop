import UIKit

protocol LogDetailViewModelDelegate: AnyObject {
    func logDetailViewModelDidRequestEdit(_ viewModel: LogDetailViewModel)
    func logDetailViewModelDidRequestDelete(_ viewModel: LogDetailViewModel)
}

final class LogDetailViewModel {
    
    weak var delegate: LogDetailViewModelDelegate?
    
    let logImage: UIImage?
    let catIcon: UIImage?
    let catName: String
    let memo: String
    private let logId: String
    
    init(logId: String, logImage: UIImage?, catIcon: UIImage?, catName: String, memo: String) {
        self.logId = logId
        self.logImage = logImage
        self.catIcon = catIcon
        self.catName = catName
        self.memo = memo
    }
    
    func editLog() {
        delegate?.logDetailViewModelDidRequestEdit(self)
    }
    
    func deleteLog() {
        delegate?.logDetailViewModelDidRequestDelete(self)
    }
    
    func getLogId() -> String {
        return logId
    }
}
