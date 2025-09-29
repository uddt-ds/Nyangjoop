//
//  LogViewModel.swift
//  Nyangjoop
//
//  Created by Lee on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class LogViewModel: ViewModelProtocol {
    private var disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let catSelected: Observable<Cat?>
        let addLogButtonTapped: Observable<Void>
    }

    struct Output {
        let cats: Driver<[Cat]>
        let visitLogs: Driver<[VisitLog]>
        let selectedCat: Driver<Cat?>
        let presentLogRecord: Driver<Cat?>
    }

    private let catsRelay = BehaviorRelay<[Cat]>(value: [])
    private let visitLogRelay = BehaviorRelay<[VisitLog]>(value: [])
    private let selectedCatRelay = BehaviorRelay<Cat?>(value: nil)

    var numberOfCats: Int {
        return catsRelay.value.count
    }

    var numberOfVisitLogs: Int {
        return visitLogRelay.value.count
    }

    func cat(at index: Int) -> Cat {
        return catsRelay.value[index]
    }

    func visitLog(at index: Int) -> VisitLog {
        return visitLogRelay.value[index]
    }

    func isSelectedCat(at index: Int) -> Bool {
        guard let selectedCat = selectedCatRelay.value else { return false }
        return catsRelay.value[index].id == selectedCat.id
    }

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(with: self) { owner, _ in
                owner.loadCats()
                owner.loadAllVisitLogs()
            }
            .disposed(by: disposeBag)

        input.catSelected
            .do { [weak self] cat in
                guard let self else { return }
                self.selectedCatRelay.accept(cat)
            }
            .subscribe(with: self) { owner, selectedCat in
                owner.loadVisitLogs(for: selectedCat)
            }
            .disposed(by: disposeBag)

        let presentLogRecord = input.addLogButtonTapped
            .withLatestFrom(selectedCatRelay.asObservable())
            .asDriver(onErrorJustReturn: nil)

        return Output(cats: catsRelay.asDriver(),
                      visitLogs: visitLogRelay.asDriver(),
                      selectedCat: selectedCatRelay.asDriver(),
                      presentLogRecord: presentLogRecord)

    }

    private func loadCats() {
        let cats = Array(realmManager.fetchAllCats())
        catsRelay.accept(cats)

        if let firstCat = cats.first {
            selectedCatRelay.accept(firstCat)

        }
    }

    private func loadAllVisitLogs() {
        let visitLogs = Array(realmManager.fetchAllVisitLogs())
        visitLogRelay.accept(visitLogs)
    }

    private func loadVisitLogs(for cat: Cat?) {
        guard let cat else {
            loadAllVisitLogs()
            return
        }

        let visitLogs = Array(cat.visitLogs).sorted { $0.date > $1.date }
        visitLogRelay.accept(visitLogs)
    }

}
