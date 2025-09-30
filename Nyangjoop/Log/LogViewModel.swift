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
        let viewWillAppear: Observable<Void>
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
        return catsRelay.value.count + 1  // "전체" 포함
    }

    var numberOfVisitLogs: Int {
        return visitLogRelay.value.count
    }

    func cat(at index: Int) -> Cat? {
        if index == 0 { return nil }  // "전체"는 nil로 표현
        return catsRelay.value[index - 1]
    }

    func visitLog(at index: Int) -> VisitLog {
        return visitLogRelay.value[index]
    }

    func isSelectedCat(at index: Int) -> Bool {
        if index == 0 {
            return selectedCatRelay.value == nil  // "전체"가 선택되었는지
        }
        guard let selectedCat = selectedCatRelay.value else { return false }
        return catsRelay.value[index - 1].id == selectedCat.id
    }

    func transform(_ input: Input) -> Output {
        // viewDidLoad와 viewWillAppear 둘 다에서 데이터 로드
        Observable.merge(input.viewDidLoad, input.viewWillAppear)
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

        // 선택된 고양이가 삭제되었다면 "전체" 선택
        if let currentSelectedCat = selectedCatRelay.value,
           !cats.contains(where: { $0.id == currentSelectedCat.id }) {
            selectedCatRelay.accept(nil)  // "전체"로 설정
        }
        
        // 처음 로드 시 "전체" 선택 (nil이면 이미 "전체"가 선택된 상태)
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
