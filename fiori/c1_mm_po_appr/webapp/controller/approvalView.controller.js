sap.ui.define(
  [
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter",
    "sap/ui/model/json/JSONModel",
    "sap/m/ActionSheet",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/ui/core/HTML",
    "sap/m/CustomListItem",
    "sap/m/VBox",
    "sap/m/HBox",
    "sap/m/Text",
    "sap/m/Title",
    "sap/m/Avatar",
    "sap/m/ObjectNumber",
    "sap/m/ColumnListItem",
    "sap/m/FeedListItem",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/TextArea",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/BusyDialog",
  ],
  function (
    Controller,
    Filter,
    FilterOperator,
    Sorter,
    JSONModel,
    ActionSheet,
    SelectDialog,
    StandardListItem,
    HTML,
    CustomListItem,
    VBox,
    HBox,
    Text,
    Title,
    Avatar,
    ObjectNumber,
    ColumnListItem,
    FeedListItem,
    Dialog,
    Button,
    TextArea,
    MessageToast,
    MessageBox,
    BusyDialog,
  ) {
    "use strict";

    return Controller.extend("c1.mm.c1mmpoappr.controller.approvalView", {
      _sSelectedEbeln: null,
      _currentStatu: null,
      _bKpiClickBound: false,
      _sStartupEbeln: null,

      _oAmtCache: {},

      onInit: function () {
        var oRouter = this.getOwnerComponent().getRouter();

        oRouter
          .getRoute("RouteapprovalView")
          .attachPatternMatched(this._onRoute, this);

        this._sStartupEbeln = this._readStartupEbeln();
      },

      onAfterRendering: function () {
        this._bindKpiClickEvents();
      },

      _onRoute: function () {
        this.byId("selStatu").setSelectedKey("ALL");
        this._highlightKpi("ALL");
        this._loadList();
      },

      _bindKpiClickEvents: function () {
        if (this._bKpiClickBound) {
          return;
        }

        var aCards = [
          { id: "kpiCardAll", key: "ALL" },
          { id: "kpiCardING", key: "ING" },
          { id: "kpiCardAP", key: "AP" },
          { id: "kpiCardRJ", key: "RJ" },
        ];

        aCards.forEach(
          function (oCard) {
            var oCtrl = this.byId(oCard.id);

            if (!oCtrl) {
              return;
            }

            oCtrl.addStyleClass("poClickable");
            oCtrl.attachBrowserEvent(
              "click",
              function () {
                this._setStatusAndReload(oCard.key);
              }.bind(this),
            );
          }.bind(this),
        );

        this._bKpiClickBound = true;
      },

      _setStatusAndReload: function (sKey) {
        this.byId("selStatu").setSelectedKey(sKey || "ALL");
        this._highlightKpi(sKey || "ALL");
        this._loadList();
      },

      _highlightKpi: function (sKey) {
        var mMap = {
          ALL: "kpiCardAll",
          ING: "kpiCardING",
          AP: "kpiCardAP",
          RJ: "kpiCardRJ",
        };
        Object.keys(mMap).forEach(
          function (k) {
            var oCtrl = this.byId(mMap[k]);
            if (!oCtrl) return;
            oCtrl.removeStyleClass("poKpiPill--active");
            if (k === sKey) oCtrl.addStyleClass("poKpiPill--active");
          }.bind(this),
        );
      },

      _loadList: function () {
        var oList = this.byId("poList");
        var aFilters = this._buildFilters();

        if (!oList) {
          return;
        }

        oList.setBusy(true);
        oList.unbindItems();

        oList.bindItems({
          path: "/PoApproval",
          filters: aFilters,
          template: this._getListTemplate(),
          templateShareable: false,
          events: {
            dataRequested: function () {
              this.byId("listHeader").setText("결재 리스트");
              this.byId("listSubHeader").setText("로딩 중...");
            }.bind(this),

            dataReceived: function (oEvent) {
              oList.setBusy(false);

              var oData = oEvent.getParameter("data");

              if (oData && oData.error) {
                MessageToast.show("구매오더 목록 조회 중 오류가 발생했습니다.");
              }

              setTimeout(
                function () {
                  var nCnt = oList.getItems().length;
                  this.byId("listHeader").setText("결재 리스트");
                  this.byId("listSubHeader").setText(nCnt + "건 조회됨");

                  if (this._sStartupEbeln) {
                    this._openStartupDetail();
                  }

                  // 결재대기(FT/PD) + 로그인 직급 권한 있는 행만 체크 가능
                  this._applyRowSelectable(oList);

                  // 리스트 전체 PO 총금액 로딩
                  this._loadAllAmounts(oList.getItems());
                }.bind(this),
                0,
              );

              this._refreshKpi();
              this._refreshKpiAmounts();
            }.bind(this),
          },
        });
      },

      _loadAllAmounts: function (aListItems) {
        var oModel = this.getOwnerComponent().getModel();

        aListItems.forEach(
          function (oListItem) {
            var oCtx = oListItem.getBindingContext();
            if (!oCtx) return;
            var sEbeln = oCtx.getProperty("Ebeln");
            if (!sEbeln) return;

            oModel.read("/PoItem", {
              filters: [new Filter("Ebeln", FilterOperator.EQ, sEbeln)],
              success: function (oData) {
                var aItems = oData && oData.results ? oData.results : [];
                var nTotal = this._calcTotal(aItems);
                if (nTotal <= 0) return;
                var sWaers =
                  (aItems.length ? (aItems[0].Waers || "").trim() : "") ||
                  "KRW";
                oListItem
                  .$()
                  .find(".poListAmount")
                  .text("총 금액 " + this.fmtNumber(nTotal) + " " + sWaers);
              }.bind(this),
            });
          }.bind(this),
        );
      },

      // 상태별(전체/결재대기/승인/반려) 합계 금액을 KPI 카드에 표시
      _refreshKpiAmounts: function (bForce) {
        // 합계는 상태 필터와 무관 → 한 번만 계산하고 캐시 (승인/반려 후엔 bForce)
        if (this._bKpiAmtLoaded && !bForce) {
          return;
        }
        this._bKpiAmtLoaded = true;

        var oModel = this.getOwnerComponent().getModel();

        if (bForce) {
          ["kpiAllAmt", "kpiIngAmt", "kpiApAmt", "kpiRjAmt"].forEach(
            function (id) {
              this.byId(id).setText("합계 …");
            }.bind(this),
          );
        }

        // 1) BSART<>ZAPC 인 모든 PO의 상태 맵
        oModel.read("/PoApproval", {
          filters: [new Filter("Bsart", FilterOperator.NE, "ZAPC")],
          urlParameters: { $top: "1000" },
          success: function (oHd) {
            var aHd = (oHd && oHd.results) || [];
            var mStatu = {};
            aHd.forEach(function (h) {
              mStatu[h.Ebeln] = h.Statu;
            });

            // 2) 모든 PoItem 읽어 PO별 합계 → 상태별 누적
            oModel.read("/PoItem", {
              urlParameters: { $top: "5000" },
              success: function (oIt) {
                var aIt = (oIt && oIt.results) || [];
                var mAmt = {};
                var sWaers = "KRW";
                aIt.forEach(function (it) {
                  var e = it.Ebeln;
                  if (!(e in mStatu)) return; // ZAPC 등 제외
                  var n = (Number(it.Menge) || 0) * (Number(it.Netpr) || 0);
                  mAmt[e] = (mAmt[e] || 0) + n;
                  if (it.Waers) sWaers = (it.Waers || "").trim() || "KRW";
                });

                var nAll = 0,
                  nIng = 0,
                  nAp = 0,
                  nRj = 0;
                Object.keys(mAmt).forEach(function (e) {
                  var s = mStatu[e];
                  var v = mAmt[e];
                  if (s === "FT" || s === "PD") {
                    nIng += v;
                    nAll += v;
                  } else if (s === "AP") {
                    nAp += v;
                    nAll += v;
                  } else if (s === "RJ") {
                    nRj += v;
                    nAll += v;
                  }
                });

                var fmt = function (v) {
                  return "합계 " + this.fmtNumber(v) + " " + sWaers;
                }.bind(this);

                this.byId("kpiAllAmt").setText(fmt(nAll));
                this.byId("kpiIngAmt").setText(fmt(nIng));
                this.byId("kpiApAmt").setText(fmt(nAp));
                this.byId("kpiRjAmt").setText(fmt(nRj));
              }.bind(this),
            });
          }.bind(this),
        });
      },

      _buildFilters: function () {
        var aFilters = [];
        var sStatu = this.byId("selStatu").getSelectedKey() || "ING";
        var sPoNo = this.byId("sfPoNo").getValue() || "";
        var sLifnr = this.byId("inVendor").getValue() || "";
        var sFrom = this.byId("dpFrom").getValue() || "";
        var sTo = this.byId("dpTo").getValue() || "";

        // BSART = 'ZAPC' 가 아닌 것만 표시
        aFilters.push(new Filter("Bsart", FilterOperator.NE, "ZAPC"));

        if (sStatu === "ING") {
          aFilters.push(
            new Filter({
              filters: [
                new Filter("Statu", FilterOperator.EQ, "FT"),
                new Filter("Statu", FilterOperator.EQ, "PD"),
              ],
              and: false,
            }),
          );
        } else if (sStatu === "ALL") {
          // 전체 = 결재대기(FT+PD) + 승인(AP) + 반려(RJ)
          aFilters.push(
            new Filter({
              filters: [
                new Filter("Statu", FilterOperator.EQ, "FT"),
                new Filter("Statu", FilterOperator.EQ, "PD"),
                new Filter("Statu", FilterOperator.EQ, "AP"),
                new Filter("Statu", FilterOperator.EQ, "RJ"),
              ],
              and: false,
            }),
          );
        } else if (sStatu) {
          aFilters.push(new Filter("Statu", FilterOperator.EQ, sStatu));
        }

        if (sPoNo) {
          aFilters.push(new Filter("Ebeln", FilterOperator.Contains, sPoNo));
        }

        if (sLifnr) {
          aFilters.push(new Filter("Lifnr", FilterOperator.Contains, sLifnr));
        }

        if (sFrom) {
          aFilters.push(new Filter("Bedat", FilterOperator.GE, sFrom));
        }

        if (sTo) {
          aFilters.push(new Filter("Bedat", FilterOperator.LE, sTo));
        }

        return aFilters;
      },

      _refreshKpi: function () {
        var oModel = this.getOwnerComponent().getModel();

        var fnCount = function (sStatus) {
          return new Promise(function (resolve) {
            // BSART = 'ZAPC' 가 아닌 것만 카운트
            var aFilters = [new Filter("Bsart", FilterOperator.NE, "ZAPC")];

            if (sStatus && sStatus !== "ALL") {
              aFilters.push(new Filter("Statu", FilterOperator.EQ, sStatus));
            }

            oModel.read("/PoApproval/$count", {
              filters: aFilters,
              success: function (v) {
                resolve(parseInt(v, 10) || 0);
              },
              error: function () {
                resolve(0);
              },
            });
          });
        };

        Promise.all([
          fnCount("FT"),
          fnCount("PD"),
          fnCount("AP"),
          fnCount("RJ"),
        ]).then(
          function (a) {
            var nFt = a[0];
            var nPd = a[1];
            var nAp = a[2];
            var nRj = a[3];
            var nIng = nFt + nPd;
            var nAll = nIng + nAp + nRj;

            this.byId("kpiAllCnt").setText(String(nAll));
            this.byId("kpiIngCnt").setText(String(nIng));
            this.byId("kpiApCnt").setText(String(nAp));
            this.byId("kpiRjCnt").setText(String(nRj));
          }.bind(this),
        );
      },

      _getListTemplate: function () {
        return new CustomListItem({
          type: "Active",
          press: this.onItemPress.bind(this),
          content: [
            new HBox({
              alignItems: "Center",
              items: [
                new VBox({
                  items: [
                    new Text({
                      text: {
                        parts: [{ path: "Lifnr" }, { path: "Name1" }],
                        formatter: this.fmtVendorName.bind(this),
                      },
                      maxLines: 1,
                    }).addStyleClass("poListVendor"),

                    new Text({ text: "{Ebeln}" }).addStyleClass("poListNo"),
                  ],
                }).addStyleClass("poListMain"),

                new VBox({
                  alignItems: "End",
                  items: [
                    new Text({
                      text: {
                        parts: [
                          { path: "TotalAmount" },
                          { path: "TotalAmt" },
                          { path: "Netwr" },
                          { path: "Waers" },
                        ],
                        formatter: this.fmtAmountText.bind(this),
                      },
                    }).addStyleClass("poListAmount"),

                    new HTML({
                      content: {
                        path: "Statu",
                        formatter: this.fmtStatuBadge.bind(this),
                      },
                      preferDOM: false,
                    }),
                  ],
                }).addStyleClass("poListSide"),
              ],
            }).addStyleClass("poListItemInner"),
          ],
        }).addStyleClass("poListItem");
      },

      onSearch: function () {
        this._loadList();
      },

      onReset: function () {
        this.byId("sfPoNo").setValue("");
        this.byId("inVendor").setValue("");
        this.byId("selStatu").setSelectedKey("ALL");
        this.byId("dpFrom").setValue("");
        this.byId("dpTo").setValue("");
        this._highlightKpi("ALL");
        this._sSelectedEbeln = null;
        this._currentStatu = null;
        this.byId("detailPanel").setVisible(false);
        this.byId("emptyDetail").setVisible(true);
        this._loadList();
      },

      onFilterSearch: function () {
        this._loadList();
      },

      onStatuChange: function () {
        this._loadList();
      },

      onPoNoValueHelp: function () {
        this._openValueHelp({
          title: "구매오더 번호 선택",
          field: "Ebeln",
          subField: "Lifnr",
          subPrefix: "공급업체 ",
          targetId: "sfPoNo",
        });
      },

      onVendorValueHelp: function () {
        this._openValueHelp({
          title: "공급업체 선택",
          field: "Lifnr",
          subField: "Name1",
          subPrefix: "",
          targetId: "inVendor",
        });
      },

      _openValueHelp: function (oCfg) {
        var oModel = this.getOwnerComponent().getModel();
        var that = this;

        var oDialog = new SelectDialog({
          title: oCfg.title,
          search: function (oEvt) {
            var sVal = oEvt.getParameter("value");
            var aFilters = sVal
              ? [new Filter(oCfg.field, FilterOperator.Contains, sVal)]
              : [];
            oEvt.getSource().getBinding("items").filter(aFilters);
          },
          confirm: function (oEvt) {
            var oItem = oEvt.getParameter("selectedItem");
            if (oItem) {
              that.byId(oCfg.targetId).setValue(oItem.getTitle());
            }
          },
        });

        // 기존 PoApproval 데이터(BSART=NB)에서 distinct 값 추출
        oModel.read("/PoApproval", {
          filters: [new Filter("Bsart", FilterOperator.NE, "ZAPC")],
          urlParameters: { $top: "500" },
          success: function (oData) {
            var aRows = (oData && oData.results) || [];
            var oSeen = {};
            var aItems = [];

            aRows.forEach(function (r) {
              var sKey = r[oCfg.field];
              if (!sKey || oSeen[sKey]) return;
              oSeen[sKey] = true;
              aItems.push({
                key: sKey,
                desc: oCfg.subField
                  ? oCfg.subPrefix + (r[oCfg.subField] || "")
                  : "",
              });
            });

            aItems.sort(function (a, b) {
              return a.key < b.key ? -1 : 1;
            });

            var oJson = new JSONModel({ items: aItems });
            oDialog.setModel(oJson);
            oDialog.bindAggregation("items", {
              path: "/items",
              template: new StandardListItem({
                title: "{key}",
                description: "{desc}",
              }),
            });
          },
          error: function () {
            MessageToast.show("서치헬프 데이터를 불러오지 못했습니다.");
          },
        });

        this.getView().addDependent(oDialog);
        oDialog.open();
      },

      onSortPress: function (oEvent) {
        var oButton = oEvent.getSource();

        // 매번 새로 구성 (결재유형 정렬은 결재대기일 때만 노출)
        if (this._oSortMenu) {
          this._oSortMenu.destroy();
          this._oSortMenu = null;
        }

        var aButtons = [
          new Button({
            text: "구매오더번호 ↑",
            press: this._applySort.bind(this, "Ebeln", false),
          }),
          new Button({
            text: "구매오더번호 ↓",
            press: this._applySort.bind(this, "Ebeln", true),
          }),
          new Button({
            text: "공급업체 ↑",
            press: this._applySort.bind(this, "Lifnr", false),
          }),
          new Button({
            text: "생성일 ↑",
            press: this._applySort.bind(this, "Bedat", false),
          }),
          new Button({
            text: "생성일 ↓",
            press: this._applySort.bind(this, "Bedat", true),
          }),
        ];

        // 결재대기 상태에서만 전결/일반결재 정렬 제공
        if (this.byId("selStatu").getSelectedKey() === "ING") {
          aButtons.push(
            new Button({
              text: "결재유형(전결/일반결재)",
              press: this._applySort.bind(this, "Statu", false),
            }),
          );
        }

        this._oSortMenu = new ActionSheet({
          title: "정렬 기준",
          buttons: aButtons,
        });
        this.getView().addDependent(this._oSortMenu);
        this._oSortMenu.openBy(oButton);
      },

      _applySort: function (sField, bDesc) {
        this._oSorter = new Sorter(sField, bDesc);
        var oBinding = this.byId("poList").getBinding("items");
        if (oBinding) {
          oBinding.sort(this._oSorter);
        } else {
          this._loadList();
        }
      },

      onRefresh: function () {
        this._bKpiAmtLoaded = false;
        this._loadList();

        if (this._sSelectedEbeln) {
          this._loadDetailData(this._sSelectedEbeln);
        }

        MessageToast.show("새로고침 완료");
      },

      onShortcut: function (oEvent) {
        var sId = oEvent.getSource().getId().split("--").pop();
        var mMap = {
          scING: "ING",
          scFT: "FT",
          scAP: "AP",
          scRJ: "RJ",
        };

        this._setStatusAndReload(mMap[sId] || "ING");
      },

      onItemSelect: function (oEvent) {
        var oItem = oEvent.getParameter("listItem");
        var oCtx = oItem && oItem.getBindingContext();

        if (oCtx) {
          this._showDetail(oCtx.getObject());
        }
      },

      onItemPress: function (oEvent) {
        var oCtx = oEvent.getSource().getBindingContext();

        if (oCtx) {
          this._showDetail(oCtx.getObject());
        }
      },

      onSelectionChange: function () {
        // 체크된 항목 중 결재대기(FT/PD) + 로그인 직급으로 승인 가능한 건만 대상
        var aSel = this.byId("poList").getSelectedItems();
        var nApprovable = 0;

        aSel.forEach(function (oItem) {
          // 전체선택 등으로 권한 없는 행이 선택되면 즉시 해제
          if (
            oItem.hasStyleClass("poNoAuth") ||
            oItem.hasStyleClass("poNoSelect")
          ) {
            oItem.setSelected(false);
            return;
          }
          var oCtx = oItem.getBindingContext();
          if (!oCtx) return;
          var s = oCtx.getProperty("Statu");
          if ((s === "FT" || s === "PD") && this._canGradeApprove(s)) {
            nApprovable++;
          }
        }, this);

        this.byId("btnBulkApprove").setEnabled(nApprovable > 0);
      },

      // 전체 선택 체크박스 : 직급 권한 있는 결재대기(FT/PD) 행만 일괄 선택/해제
      onSelectAllCheck: function (oEvent) {
        var bChecked = oEvent.getParameter("selected");
        var oList = this.byId("poList");

        var aSelectable = oList.getItems().filter(function (oItem) {
          if (oItem.hasStyleClass("poNoAuth") || oItem.hasStyleClass("poNoSelect")) {
            return false;
          }
          var oCtx = oItem.getBindingContext();
          if (!oCtx) return false;
          var s = oCtx.getProperty("Statu");
          return (s === "FT" || s === "PD") && this._canGradeApprove(s);
        }, this);

        if (bChecked && !aSelectable.length) {
          MessageToast.show("현재 직급으로 선택 가능한 결재대기 건이 없습니다.");
          this.byId("cbSelectAll").setSelected(false);
          return;
        }

        aSelectable.forEach(function (oItem) {
          oItem.setSelected(bChecked);
        });
        this.onSelectionChange();
      },

      onBulkApprove: function () {
        var aSel = this.byId("poList").getSelectedItems();
        var aTargets = [];
        var nNoAuth = 0; // 결재대기지만 직급 권한이 없어 제외된 건

        aSel.forEach(function (oItem) {
          var oCtx = oItem.getBindingContext();
          if (!oCtx) return;
          var o = oCtx.getObject();
          if (o.Statu === "FT" || o.Statu === "PD") {
            if (this._canGradeApprove(o.Statu)) {
              aTargets.push(o.Ebeln);
            } else {
              nNoAuth++;
            }
          }
        }, this);

        if (!aTargets.length) {
          MessageToast.show(
            nNoAuth
              ? "현재 직급으로 일괄 승인 가능한 항목이 없습니다. (일반결재는 부장만 가능)"
              : "승인 가능한(결재대기) 항목을 선택하세요.",
          );
          return;
        }

        MessageBox.confirm(
          "선택한 " +
            aTargets.length +
            "건을 일괄 승인하시겠습니까?" +
            (nNoAuth
              ? "\n(직급 권한이 없는 " + nNoAuth + "건은 제외됩니다.)"
              : ""),
          {
            title: "일괄 승인",
            onClose: function (sAction) {
              if (sAction === MessageBox.Action.OK) {
                this._bulkApproveRun(aTargets);
              }
            }.bind(this),
          },
        );
      },

      _bulkApproveRun: function (aEbeln) {
        var oModel = this.getOwnerComponent().getModel();
        var oBusy = new BusyDialog({ text: "일괄 승인 처리 중..." });
        oBusy.open();

        var aPromises = aEbeln.map(function (sEbeln) {
          return new Promise(function (resolve) {
            oModel.callFunction("/approve", {
              method: "POST",
              urlParameters: { Ebeln: sEbeln },
              success: function () {
                resolve({ ebeln: sEbeln, ok: true });
              },
              error: function () {
                resolve({ ebeln: sEbeln, ok: false });
              },
            });
          });
        });

        Promise.all(aPromises).then(
          function (aRes) {
            oBusy.close();
            var nOk = aRes.filter(function (r) {
              return r.ok;
            }).length;
            var nFail = aRes.length - nOk;

            oModel.refresh(true);
            this._bKpiAmtLoaded = false;
            this._loadList();
            this.byId("detailPanel").setVisible(false);
            this.byId("emptyDetail").setVisible(true);
            this.byId("btnBulkApprove").setEnabled(false);

            MessageBox.success(
              "일괄 승인 완료: 성공 " +
                nOk +
                "건" +
                (nFail ? " / 실패 " + nFail + "건" : ""),
            );
          }.bind(this),
        );
      },

      _showDetail: function (oData) {
        this._sSelectedEbeln = oData.Ebeln;
        this._currentStatu = oData.Statu;
        // 로그인 사용자 직급(CDS MyGrade) — 버튼 권한 판정용
        this._myGrade = (oData.MyGrade || "").trim();

        this.byId("emptyDetail").setVisible(false);
        this.byId("detailPanel").setVisible(true);

        this.byId("detailTabMain").setSelectedKey("overview");
        this._highlightRail("overview");
        ["tabOverview", "tabItems", "tabHistory", "tabPdf"].forEach(
          function (sId) {
            this.byId(sId).setVisible(sId === "tabOverview");
          }.bind(this),
        );

        setTimeout(function () {
          var aEls = document.querySelectorAll(".poTabContent");
          aEls.forEach(function (el) {
            el.scrollTop = 0;
          });
        }, 0);

        this.byId("dHdrEbeln").setText(oData.Ebeln || "");
        this.byId("dHdrBadge").setContent(this.fmtStatuBadge(oData.Statu));
        this.byId("dHdrVendor").setText(
          this.fmtVendor(oData.Lifnr, oData.Name1),
        );
        this.byId("dHdrPlant").setText(this.fmtPlant(oData.Werks));
        this.byId("dHdrDate").setText(this.fmtDate(oData.Bedat));

        var sAmount = this._getAmountValue(oData);
        var sWaers = (oData.Waers || "").trim() || "KRW";
        var nAmt = Number(sAmount);
        this.byId("dHdrAmt").setText(
          sAmount && !isNaN(nAmt) && nAmt !== 0
            ? this.fmtNumber(Math.round(nAmt)) + " " + sWaers
            : "- " + sWaers,
        );

        this.byId("dBaseBsart").setText(this.fmtBsart(oData.Bsart));
        this.byId("dBaseErnam").setText(oData.Ernam || "-");
        this.byId("dBaseErdat").setText(this.fmtDate(oData.Bedat) || "-");
        this.byId("dBaseStatus").setText(this.fmtStatuPlain(oData.Statu));
        var oStTile = this.byId("dBaseStatus");
        oStTile.removeStyleClass("poTileVal--blue");
        oStTile.removeStyleClass("poTileVal--green");
        oStTile.removeStyleClass("poTileVal--red");
        if (oData.Statu === "AP") {
          oStTile.addStyleClass("poTileVal--green");
        } else if (oData.Statu === "RJ") {
          oStTile.addStyleClass("poTileVal--red");
        } else {
          oStTile.addStyleClass("poTileVal--blue");
        }

        // 구매사유는 품목(PR) 단위 → _loadItems 후 _applyReasons로 채움
        this.byId("dReasonTitle").setText("구매 사유 로딩 중...");
        this.byId("dReasonText").setText("");

        // 반려사유: 현재 상태가 RJ일 때만 개요에 표시
        // (BIGO는 구매사유 요약으로 역할 변경됨 → 반려사유는 결재이력에서 조회)
        var bRejected = oData.Statu === "RJ";
        this.byId("rejectInfoPanel").setVisible(bRejected);
        if (bRejected) {
          this.byId("dBaseBigo").setText("조회 중...");
        }

        this._refreshActionBar();
        this._loadDetailData(oData.Ebeln);
      },

      _loadDetailData: function (sEbeln) {
        this.byId("itemTableMain").setBusy(true);
        this.byId("mrpMiniTable").setBusy(true);
        this.byId("historyList").setBusy(true);

        this._loadItems(sEbeln);
        this._loadHistory(sEbeln);
      },

      _loadItems: function (sEbeln) {
        var aFilter = [new Filter("Ebeln", FilterOperator.EQ, sEbeln)];

        this.byId("itemTableMain").bindItems({
          path: "/PoItem",
          filters: aFilter,
          template: this._getItemTpl(),
          templateShareable: false,
          events: {
            dataReceived: function (oEvent) {
              this.byId("itemTableMain").setBusy(false);
              // mrpMiniTable은 동일 /PoItem 캐시로 dataReceived가 안 올 수 있어 함께 해제
              var oMrp = this.byId("mrpMiniTable");
              if (oMrp) oMrp.setBusy(false);

              var oData = oEvent.getParameter("data");
              var aItems = oData && oData.results ? oData.results : [];
              var nTotal = this._calcTotal(aItems);
              var sWaers =
                (aItems.length ? (aItems[0].Waers || "").trim() : "") || "KRW";
              var sTotalText =
                nTotal > 0
                  ? this.fmtNumber(nTotal) + " " + sWaers
                  : "- " + sWaers;

              // 품목 탭 요약 카드 (검색 시에도 갱신)
              var oSumAmt = this.byId("dItemSumAmt");
              var oSumCnt = this.byId("dItemSumCnt");
              var oSumDate = this.byId("dItemSumDate");
              if (oSumAmt)
                oSumAmt.setText(
                  nTotal > 0 ? this.fmtNumber(nTotal) + " " + sWaers : "-",
                );
              if (oSumCnt) oSumCnt.setText(aItems.length + "건");
              if (oSumDate)
                oSumDate.setText(this._minDeliveryDate(aItems) || "-");

              // 아래는 전체 로드 시에만 (품목 검색 필터 시엔 헤더 금액/사유 고정)
              if (!this._bItemFilter) {
                this.byId("dHdrAmt").setText(sTotalText);

                // 개요 구매사유: 아이템들의 고유(distinct) 사유 표시
                this._applyReasons(aItems);

                // 리스트 해당 아이템 총금액 업데이트
                var oList = this.byId("poList");
                var sEbeln = this._sSelectedEbeln;
                if (oList && sEbeln && nTotal > 0) {
                  oList.getItems().forEach(
                    function (oItem) {
                      var oCtx = oItem.getBindingContext();
                      if (oCtx && oCtx.getProperty("Ebeln") === sEbeln) {
                        var aTexts = oItem.$().find(".poListAmount");
                        if (aTexts.length) {
                          aTexts.text(
                            "총 금액 " + this.fmtNumber(nTotal) + " " + sWaers,
                          );
                        }
                      }
                    }.bind(this),
                  );
                }
              }
              this._bItemFilter = false;
            }.bind(this),
          },
        });

        this.byId("mrpMiniTable").bindItems({
          path: "/PoItem",
          filters: aFilter,
          template: this._getMrpMiniTpl(),
          templateShareable: false,
          events: {
            dataReceived: function () {
              this.byId("mrpMiniTable").setBusy(false);
            }.bind(this),
          },
        });
      },

      _loadHistory: function (sEbeln) {
        var oModel = this.getOwnerComponent().getModel();
        var aFilter = [new Filter("Ebeln", FilterOperator.EQ, sEbeln)];

        oModel.read("/PoHistory", {
          filters: aFilter,
          success: function (oData) {
            var aHistory = oData && oData.results ? oData.results : [];

            this._renderStamps("stampBoxFull", aHistory);

            // 상신자 = 상신(SB)/재상신(RS) 기록의 처리자 (이력 데이터 재활용)
            this._applySubmitter(aHistory);

            // 반려사유 = 결재이력 최신 RJ 코멘트 (BIGO 아님)
            this._applyRejectReason(aHistory);

            this.byId("historyList").bindItems({
              path: "/PoHistory",
              filters: aFilter,
              template: this._getHistoryTpl(),
              templateShareable: false,
            });

            this.byId("historyList").setBusy(false);
          }.bind(this),

          error: function (oErr) {
            this.byId("historyList").setBusy(false);
            MessageBox.error(
              "결재이력 조회 중 오류가 발생했습니다.\n" + this._parseErr(oErr),
            );
          }.bind(this),
        });
      },

      _applyReasons: function (aItems) {
        // 아이템들의 고유 구매사유 코드 추출
        var oSeen = {};
        var aCodes = [];
        (aItems || []).forEach(function (it) {
          var c = (it.Purrsn || "").trim();
          if (c && !oSeen[c]) {
            oSeen[c] = true;
            aCodes.push(c);
          }
        });

        if (!aCodes.length) {
          this.byId("dReasonTitle").setText("구매 사유 없음");
          this.byId("dReasonText").setText("등록된 구매 사유가 없습니다.");
          return;
        }

        var aNames = aCodes.map(this.fmtReason.bind(this));

        if (aCodes.length === 1) {
          this.byId("dReasonTitle").setText(aNames[0]);
          this.byId("dReasonText").setText(
            aCodes[0] === "MRP"
              ? "생산 계획 정상 이행을 위해 부족 자재를 구매하고자 합니다."
              : "구매 요청 사유에 따라 구매를 진행합니다.",
          );
        } else {
          // 여러 사유가 섞인 경우
          this.byId("dReasonTitle").setText(
            "복합 사유 (" + aCodes.length + "건)",
          );
          this.byId("dReasonText").setText(aNames.join(" · "));
        }
      },

      _submitterFromHistory: function (aHistory, sFallback) {
        var aSubmit = (aHistory || []).filter(function (h) {
          return h.Action === "SB" || h.Action === "RS";
        });

        if (!aSubmit.length) {
          return sFallback || "-";
        }

        aSubmit.sort(function (a, b) {
          return (parseInt(b.Seqnr, 10) || 0) - (parseInt(a.Seqnr, 10) || 0);
        });

        var oSub = aSubmit[0];
        var sName = (oSub.Ename || "").trim();
        var sGrade = (oSub.Zgrade || "").trim();
        return sName
          ? sName + (sGrade ? " / " + sGrade : "")
          : oSub.Uname || sFallback || "-";
      },

      _applySubmitter: function (aHistory) {
        var sText = this._submitterFromHistory(aHistory, null);
        if (sText && sText !== "-") {
          this.byId("dBaseErnam").setText(sText);
        }
      },

      _applyRejectReason: function (aHistory) {
        // 현재 상태가 RJ일 때만 표시 (rejectInfoPanel은 _showDetail에서 제어)
        if (this._currentStatu !== "RJ") {
          return;
        }

        // 결재이력 중 ACTION='RJ' 의 최신(Seqnr 큰) 코멘트
        var aRej = (aHistory || []).filter(function (h) {
          return h.Action === "RJ";
        });

        aRej.sort(function (a, b) {
          return (parseInt(b.Seqnr, 10) || 0) - (parseInt(a.Seqnr, 10) || 0);
        });

        var sReason =
          aRej.length && aRej[0].ApprComment
            ? aRej[0].ApprComment
            : "반려 사유 없음";

        this.byId("dBaseBigo").setText(sReason);
      },

      _highlightRail: function (sKey) {
        var oRail = this.byId("detailRail");
        if (!oRail) return;
        oRail.getItems().forEach(function (oBtn) {
          if (!oBtn.data) return;
          oBtn.removeStyleClass("poRailBtn--active");
          if (oBtn.data("tabKey") === sKey) {
            oBtn.addStyleClass("poRailBtn--active");
          }
        });
      },

      onRailSelect: function (oEvent) {
        var oBtn = oEvent.getSource();
        var sKey = oBtn.data("tabKey");
        this._highlightRail(sKey);
        this.byId("detailTabMain").setSelectedKey(sKey);
        this.onTabSelect({
          getParameter: function () {
            return sKey;
          },
        });
      },

      onTabSelect: function (oEvent) {
        var sKey =
          oEvent.getParameter("selectedKey") || oEvent.getParameter("key");

        var m = {
          overview: "tabOverview",
          items: "tabItems",
          history: "tabHistory",
          pdf: "tabPdf",
        };

        Object.keys(m).forEach(
          function (k) {
            this.byId(m[k]).setVisible(false);
          }.bind(this),
        );

        if (m[sKey]) {
          this.byId(m[sKey]).setVisible(true);
        }

        if (sKey === "pdf") {
          this._renderPdfPreview();
        }
      },

      _refreshActionBar: function () {
        // 결재대기(전결/일반결재) 상태 + 로그인 사용자 직급 권한 둘 다 충족해야 처리
        var bWaiting =
          this._currentStatu === "FT" || this._currentStatu === "PD";
        var bGradeOk = this._canGradeApprove(this._currentStatu);
        var bCanAct = bWaiting && bGradeOk;

        // 권한 없거나 처리 완료 건은 승인/반려 버튼 숨김
        this.byId("btnReject").setVisible(bCanAct);
        this.byId("btnApprove").setVisible(bCanAct);

        var sHint;
        if (bCanAct) {
          sHint =
            this._currentStatu === "FT"
              ? "전결 대상입니다. 승인 또는 반려 처리할 수 있습니다."
              : "일반결재 대상입니다. 승인 또는 반려 처리할 수 있습니다.";
        } else if (bWaiting && !bGradeOk) {
          sHint = "현재 직급으로는 이 건을 결재할 수 없습니다.";
        } else if (this._currentStatu === "AP") {
          sHint = "승인 완료된 구매오더입니다.";
        } else if (this._currentStatu === "RJ") {
          sHint = "반려된 구매오더입니다.";
        } else {
          sHint = "결재 처리 대상이 아닙니다.";
        }
        this.byId("actionHint").setText(sHint);
      },

      // 로그인 사용자 직급(MyGrade)으로 승인 가능 여부 판정
      // 전결(FT): 차장/책임/부장   일반결재(PD): 부장   (고문 등 제외)
      _canGradeApprove: function (sStatu) {
        var g = (this._myGrade || "").trim();
        if (!g) {
          // MyGrade가 아직 안 내려오면(미구현/조회중) 막지 않음 → 기존처럼 표시
          return true;
        }
        if (sStatu === "FT") {
          return ["차장", "책임", "부장"].indexOf(g) >= 0;
        }
        if (sStatu === "PD") {
          return g === "부장";
        }
        return false;
      },

      // 결재대기(FT/PD) + 로그인 직급 권한이 있는 행만 체크 가능하도록 설정
      // (권한 없는 건은 체크박스 자체를 비활성화 → 애초에 선택 불가)
      _applyRowSelectable: function (oList) {
        oList = oList || this.byId("poList");
        var aItems = oList.getItems();

        // 로그인 직급: 행 컨텍스트의 MyGrade에서 확보 (상세 클릭 전에도 사용)
        aItems.some(function (oItem) {
          var oCtx = oItem.getBindingContext();
          var sG = oCtx && oCtx.getProperty("MyGrade");
          if (sG) {
            this._myGrade = sG.trim();
            return true;
          }
          return false;
        }, this);

        aItems.forEach(function (oItem) {
          var oCtx = oItem.getBindingContext();
          if (!oCtx) return;
          var s = oCtx.getProperty("Statu");
          var bPending = s === "FT" || s === "PD";

          if (!bPending) {
            // 승인완료/반려 등 결재대상 아님 → 체크박스 숨김
            oItem.setSelected(false);
            if (oItem.setSelectable) {
              oItem.setSelectable(false);
            }
            oItem.addStyleClass("poNoSelect");
            oItem.removeStyleClass("poNoAuth");
          } else if (!this._canGradeApprove(s)) {
            // 결재대상이나 직급 권한 없음 → 회색·비활성(보임)
            oItem.setSelected(false);
            if (oItem.setSelectable) {
              oItem.setSelectable(true);
            }
            oItem.addStyleClass("poNoAuth");
            oItem.removeStyleClass("poNoSelect");
          } else {
            // 결재대상 + 권한 있음 → 체크 가능
            if (oItem.setSelectable) {
              oItem.setSelectable(true);
            }
            oItem.removeStyleClass("poNoSelect");
            oItem.removeStyleClass("poNoAuth");
          }
        }, this);

        // 체크 가능 항목 변화 → 일괄승인 버튼 상태 갱신
        this.onSelectionChange();
      },

      _getItemTpl: function () {
        return new ColumnListItem({
          cells: [
            new Text({
              text: "{Ebelp}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell poCenterCell"),

            new Text({
              text: "{Maktx}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell poNameCell"),

            new ObjectNumber({
              number: "{Menge}",
              unit: "{Meins}",
            }).addStyleClass("poQtyCell"),

            new Text({
              wrapping: false,
              text: {
                parts: [{ path: "Netpr" }, { path: "Waers" }],
                formatter: function (sNetpr, sWaers) {
                  if (
                    sNetpr === undefined ||
                    sNetpr === null ||
                    sNetpr === ""
                  ) {
                    return "-";
                  }

                  var n = Number(sNetpr);

                  if (isNaN(n)) {
                    return "-";
                  }

                  var sCur = (sWaers || "").trim() || "KRW";
                  return this.fmtNumber(Math.round(n)) + " " + sCur;
                }.bind(this),
              },
            }).addStyleClass("poNoWrapCell poPriceCell"),

            new Text({
              wrapping: false,
              text: {
                path: "Lfdat",
                formatter: this.fmtDate.bind(this),
              },
            }).addStyleClass("poNoWrapCell poCenterCell"),

            new Text({
              text: "{Banfn}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell poCenterCell"),

            new Text({
              wrapping: false,
              text: {
                path: "Purrsn",
                formatter: this.fmtReason.bind(this),
              },
            }).addStyleClass("poNoWrapCell"),
          ],
        });
      },

      _getMrpMiniTpl: function () {
        return new ColumnListItem({
          cells: [
            new Text({
              text: "{Matnr}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell"),

            new Text({
              text: "{Maktx}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell poNameCell"),

            new ObjectNumber({
              number: "{Menge}",
              unit: "{Meins}",
            }).addStyleClass("poQtyCell"),

            new Text({
              text: "{Banfn}",
              wrapping: false,
            }).addStyleClass("poNoWrapCell poCenterCell"),
          ],
        });
      },

      _getHistoryTpl: function () {
        return new FeedListItem({
          sender: "{Ename}",
          senderActive: false,
          info: {
            path: "Action",
            formatter: this.fmtActionText.bind(this),
          },
          timestamp: {
            path: "Actdt",
            formatter: this.fmtDate.bind(this),
          },
          text: {
            path: "ApprComment",
            formatter: this.fmtComment.bind(this),
          },
          iconInitials: {
            path: "Ename",
            formatter: this.fmtInitials.bind(this),
          },
        });
      },

      _renderStamps: function (sContainerId, aHistory) {
        var oBox = this.byId(sContainerId);

        if (!oBox) {
          return;
        }

        oBox.removeAllItems();

        var aValid = (aHistory || []).filter(function (o) {
          return ["SB", "RS", "AP", "RJ"].indexOf(o.Action) >= 0;
        });

        if (!aValid.length) {
          oBox.addItem(new Text({ text: "결재 이력이 없습니다." }));
          return;
        }

        aValid.sort(function (a, b) {
          return (parseInt(a.Seqnr, 10) || 0) - (parseInt(b.Seqnr, 10) || 0);
        });

        aValid.forEach(
          function (oH, i) {
            var oStampHtml = new HTML({
              content: this._stampHtml(oH, null),
              preferDOM: false,
            });

            // 도장 이미지를 JS로 미리 로드(CSP 안전) → 성공 시에만 이미지로 교체
            this._applyStampImage(oStampHtml, oH);

            oBox.addItem(
              new VBox({
                alignItems: "Center",
                width: "112px",
                items: [
                  oStampHtml,
                  new Text({
                    text: oH.Zgrade || "",
                    textAlign: "Center",
                  }).addStyleClass("poStampRole"),
                  new Text({
                    text: oH.Ename || "",
                    textAlign: "Center",
                  }).addStyleClass("poStampName"),
                ],
              }).addStyleClass("poStampWrap"),
            );

            if (i < aValid.length - 1) {
              oBox.addItem(
                new Text({ text: "→" }).addStyleClass("poStampArrow"),
              );
            }
          }.bind(this),
        );
      },

      // 사번 정규화: 숫자면 8자리 0채움(00000007), 그 외는 그대로
      _sealPernr: function (sPernr) {
        var p = (sPernr == null ? "" : String(sPernr)).trim();
        if (!p) return "";
        if (/^\d+$/.test(p)) {
          while (p.length < 8) {
            p = "0" + p;
          }
          return p;
        }
        return p.replace(/[^0-9A-Za-z_-]/g, "");
      },

      // 도장 이미지 프리로드: 로드되면 HTML 콘텐츠를 이미지 버전으로 교체
      _applyStampImage: function (oHtml, oH) {
        var p = this._sealPernr(oH.Pernr);
        if (!p) return;

        var sUrl = sap.ui.require.toUrl(
          "c1/mm/c1mmpoappr/img/seal/" + p + ".png",
        );

        var oImg = new window.Image();
        oImg.onload = function () {
          if (!oHtml.bIsDestroyed) {
            oHtml.setContent(this._stampHtml(oH, sUrl));
          }
        }.bind(this);
        oImg.onerror = function () {
          /* 이미지 없음 → SVG 도장 유지 */
        };
        oImg.src = sUrl;
      },

      _stampHtml: function (oH, sImgUrl) {
        var sAction = oH.Action || "";
        var sCls = "poStamp poStamp--pending";
        var sLabel = "상신";

        if (sAction === "AP") {
          sCls = "poStamp poStamp--approved";
          sLabel = "승인";
        } else if (sAction === "RJ") {
          sCls = "poStamp poStamp--rejected";
          sLabel = "반려";
        } else if (sAction === "RS") {
          sCls = "poStamp poStamp--pending";
          sLabel = "재상신";
        }

        // 이름을 세로 각인 형태로 (전각 인장 느낌)
        var sName = (oH.Ename || "").trim();
        var sSeal = sName
          ? sName
              .split("")
              .map(
                function (c) {
                  return "<span>" + this._esc(c) + "</span>";
                }.bind(this),
              )
              .join("")
          : this._esc(sLabel);

        // 이미지 URL이 주어지면(프리로드 성공) 이미지만, 아니면 SVG 도장
        if (sImgUrl) {
          return (
            '<div class="' +
            sCls +
            ' poStamp--hasImg" title="' +
            this._esc(sLabel) +
            '">' +
            '<img class="poStampImg" src="' +
            sImgUrl +
            '"/>' +
            "</div>"
          );
        }

        return (
          '<div class="' +
          sCls +
          '" title="' +
          this._esc(sLabel) +
          '">' +
          this._sealFrameSvg("poStampFrame") +
          '<div class="poStampSeal">' +
          sSeal +
          "</div>" +
          "</div>"
        );
      },

      // PDF용: 절대 URL 도장 이미지 (새 창에서도 로드되도록). 없으면 onerror로 숨김
      _sealImgTagAbs: function (sPernr, sCls) {
        var p = this._sealPernr(sPernr);
        if (!p) return "";
        var sRel = sap.ui.require.toUrl(
          "c1/mm/c1mmpoappr/img/seal/" + p + ".png",
        );
        var sAbs;
        try {
          sAbs = new URL(sRel, document.baseURI).href;
        } catch (e) {
          sAbs = sRel;
        }
        return (
          '<img class="' +
          sCls +
          '" src="' +
          sAbs +
          '" ' +
          "onerror=\"this.style.display='none'\"/>"
        );
      },

      // 인장 틀 SVG (상태색은 currentColor로 자동) — 화면/PDF 공용
      _sealFrameSvg: function (sCls) {
        return (
          '<svg class="' +
          sCls +
          '" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">' +
          '<circle cx="50" cy="50" r="46" fill="none" stroke="currentColor" stroke-width="5"/>' +
          '<circle cx="50" cy="50" r="37.5" fill="none" stroke="currentColor" stroke-width="1.3"/>' +
          // 네 귀퉁이 작은 각인 점 (전각 느낌)
          '<circle cx="50" cy="9" r="1.6" fill="currentColor"/>' +
          '<circle cx="50" cy="91" r="1.6" fill="currentColor"/>' +
          '<circle cx="9" cy="50" r="1.6" fill="currentColor"/>' +
          '<circle cx="91" cy="50" r="1.6" fill="currentColor"/>' +
          "</svg>"
        );
      },

      // 이력의 Pernr 도장 이미지를 미리 로드 → 존재하는 것만 절대URL 맵에 저장
      _preloadSeals: function (aHistory) {
        this._mSealImg = this._mSealImg || {};
        var that = this;

        var aP = [];
        (aHistory || []).forEach(function (h) {
          var p = that._sealPernr(h.Pernr);
          if (p && aP.indexOf(p) < 0) aP.push(p);
        });

        var aProm = aP.map(function (p) {
          return new Promise(function (resolve) {
            var sRel = sap.ui.require.toUrl(
              "c1/mm/c1mmpoappr/img/seal/" + p + ".png",
            );
            var sAbs;
            try {
              sAbs = new URL(sRel, document.baseURI).href;
            } catch (e) {
              sAbs = sRel;
            }
            var img = new window.Image();
            img.onload = function () {
              that._mSealImg[p] = sAbs;
              resolve();
            };
            img.onerror = function () {
              delete that._mSealImg[p];
              resolve();
            };
            img.src = sAbs;
          });
        });

        return Promise.all(aProm);
      },

      onApprove: function () {
        if (!this._sSelectedEbeln) {
          MessageToast.show("승인할 구매오더를 선택하세요.");
          return;
        }

        if (!(this._currentStatu === "FT" || this._currentStatu === "PD")) {
          MessageBox.error("현재 상태에서는 승인할 수 없습니다.");
          return;
        }

        MessageBox.confirm(
          "PO " + this._sSelectedEbeln + " 을(를) 승인하시겠습니까?",
          {
            title: "승인 확인",
            onClose: function (sAction) {
              if (sAction === MessageBox.Action.OK) {
                this._callAction("approve", "");
              }
            }.bind(this),
          },
        );
      },

      onReject: function () {
        if (!this._sSelectedEbeln) {
          MessageToast.show("반려할 구매오더를 선택하세요.");
          return;
        }

        if (!(this._currentStatu === "FT" || this._currentStatu === "PD")) {
          MessageBox.error("현재 상태에서는 반려할 수 없습니다.");
          return;
        }

        var sETC = "기타 (직접 입력)";
        var aReasons = [
          "단가 과다 / 견적 재검토 필요",
          "공급업체 변경 필요",
          "수량/납기 조정 필요",
          "예산 초과",
          "구매 사유 불충분",
          sETC,
        ];

        var oDetailLabel = new sap.m.Label({
          text: "상세 사유 (직접 입력)",
        }).addStyleClass("sapUiSmallMarginBegin sapUiTinyMarginTop");

        var oTextArea = new TextArea({
          placeholder: "반려 사유를 직접 입력하세요.",
          rows: 4,
          width: "100%",
          visible: false,
        });
        oDetailLabel.setVisible(false);

        var oReasonSelect = new sap.m.Select({
          width: "100%",
          items: aReasons.map(function (s) {
            return new sap.ui.core.Item({ key: s, text: s });
          }),
          change: function (oEvt) {
            var bEtc = oEvt.getSource().getSelectedKey() === sETC;
            // 기타일 때만 상세 입력칸 열림, 나머지는 숨김
            oDetailLabel.setVisible(bEtc);
            oTextArea.setVisible(bEtc);
            if (!bEtc) {
              oTextArea.setValue("");
            }
          },
        });
        oReasonSelect.setSelectedKey(aReasons[0]);

        var oDialog = new Dialog({
          title: "구매오더 반려",
          contentWidth: "460px",
          content: [
            new sap.m.Label({ text: "반려 사유 선택" }).addStyleClass(
              "sapUiSmallMarginBegin sapUiTinyMarginTop",
            ),
            oReasonSelect,
            oDetailLabel,
            oTextArea,
          ],
          beginButton: new Button({
            text: "반려",
            type: "Reject",
            press: function () {
              var sSelected = oReasonSelect.getSelectedKey();
              var sReason;

              if (sSelected === sETC) {
                sReason = oTextArea.getValue().trim();
                if (!sReason) {
                  MessageToast.show("기타 사유를 직접 입력하세요.");
                  return;
                }
              } else {
                // 선택한 사유 그대로 반려사유로 저장
                sReason = sSelected;
              }

              oDialog.close();
              this._callAction("reject", sReason);
            }.bind(this),
          }),
          endButton: new Button({
            text: "취소",
            press: function () {
              oDialog.close();
            },
          }),
          afterClose: function () {
            oDialog.destroy();
          },
        });

        this.getView().addDependent(oDialog);
        oDialog.open();
      },

      _callAction: function (sAction, sReason) {
        var oModel = this.getOwnerComponent().getModel();

        var oBusy = new BusyDialog({
          text: sAction === "approve" ? "승인 처리 중..." : "반려 처리 중...",
        });

        oBusy.open();

        var oParams = {
          Ebeln: this._sSelectedEbeln,
        };

        if (sAction === "reject") {
          oParams.Bigo = sReason;
        }

        oModel.callFunction("/" + sAction, {
          method: "POST",
          urlParameters: oParams,

          success: function () {
            oBusy.close();

            MessageBox.success(
              sAction === "approve"
                ? "승인 처리가 완료되었습니다."
                : "반려 처리가 완료되었습니다.",
              {
                onClose: function () {
                  oModel.refresh(true);
                  this._bKpiAmtLoaded = false;
                  this._loadList();

                  if (this._sSelectedEbeln) {
                    this._loadDetailAfterAction(this._sSelectedEbeln);
                  }
                }.bind(this),
              },
            );
          }.bind(this),

          error: function (oErr) {
            oBusy.close();
            MessageBox.error(
              "처리 중 오류가 발생했습니다.\n" + this._parseErr(oErr),
            );
          }.bind(this),
        });
      },

      _loadDetailAfterAction: function (sEbeln) {
        var oModel = this.getOwnerComponent().getModel();
        var sPath = "/PoApproval('" + encodeURIComponent(sEbeln) + "')";

        oModel.read(sPath, {
          success: function (oData) {
            this._showDetail(oData);
          }.bind(this),
          error: function () {
            this.byId("detailPanel").setVisible(false);
            this.byId("emptyDetail").setVisible(true);
          }.bind(this),
        });
      },

      onGeneratePdf: function () {
        if (!this._sSelectedEbeln) {
          MessageToast.show("PDF로 저장할 구매오더를 선택하세요.");
          return;
        }

        var oModel = this.getOwnerComponent().getModel();
        var sEbeln = this._sSelectedEbeln;
        var sHeaderPath = "/PoApproval('" + encodeURIComponent(sEbeln) + "')";

        var pHeader = new Promise(function (resolve, reject) {
          oModel.read(sHeaderPath, {
            success: resolve,
            error: reject,
          });
        });

        var pItems = new Promise(function (resolve) {
          oModel.read("/PoItem", {
            filters: [new Filter("Ebeln", FilterOperator.EQ, sEbeln)],
            success: function (oData) {
              resolve(oData && oData.results ? oData.results : []);
            },
            error: function () {
              resolve([]);
            },
          });
        });

        var pHistory = new Promise(function (resolve) {
          oModel.read("/PoHistory", {
            filters: [new Filter("Ebeln", FilterOperator.EQ, sEbeln)],
            success: function (oData) {
              resolve(oData && oData.results ? oData.results : []);
            },
            error: function () {
              resolve([]);
            },
          });
        });

        Promise.all([pHeader, pItems, pHistory])
          .then(
            function (aResult) {
              var oHeader = aResult[0];
              var aItems = aResult[1];
              var aHistory = aResult[2];

              oHeader.to_Item = { results: aItems };
              oHeader.to_History = { results: aHistory };

              // 도장 이미지 프리로드 후 빌드 (이미지/SVG 겹침 방지)
              this._preloadSeals(aHistory).then(
                function () {
                  var sHtml = this._buildPdfHtml(oHeader);
                  var oWin = window.open("", "_blank");

                  if (!oWin) {
                    MessageBox.error(
                      "팝업이 차단되었습니다. 브라우저 팝업 허용 후 다시 시도하세요.",
                    );
                    return;
                  }

                  oWin.document.open();
                  oWin.document.write(sHtml);
                  oWin.document.close();

                  setTimeout(function () {
                    oWin.focus();
                    oWin.print();
                  }, 500);
                }.bind(this),
              );
            }.bind(this),
          )
          .catch(
            function (oErr) {
              MessageBox.error(
                "PDF 데이터 조회 중 오류가 발생했습니다.\n" +
                  this._parseErr(oErr),
              );
            }.bind(this),
          );
      },

      _buildPdfHtml: function (oData) {
        var aItems = this._getNavResults(oData.to_Item);
        var aHistory = this._getNavResults(oData.to_History);
        var nTotal = this._calcTotal(aItems);
        var sWaers = oData.Waers || "";

        var sItemRows = aItems
          .map(
            function (o) {
              var nLine = (Number(o.Menge) || 0) * (Number(o.Netpr) || 0);
              return (
                "<tr>" +
                '<td class="c">' +
                this._esc(o.Ebelp) +
                "</td>" +
                "<td>" +
                this._esc(o.Matnr) +
                "</td>" +
                "<td>" +
                this._esc(o.Maktx) +
                "</td>" +
                '<td class="num">' +
                this.fmtNumber(o.Menge) +
                " " +
                this._esc(o.Meins) +
                "</td>" +
                '<td class="num">' +
                this.fmtNumber(Math.round(Number(o.Netpr) || 0)) +
                "</td>" +
                '<td class="num">' +
                this.fmtNumber(Math.round(nLine)) +
                "</td>" +
                '<td class="c">' +
                this._esc(this.fmtDate(o.Lfdat)) +
                "</td>" +
                '<td class="c">' +
                this._esc(o.Banfn) +
                "</td>" +
                "</tr>"
              );
            }.bind(this),
          )
          .join("");

        var sHistoryRows = aHistory
          .filter(function (h) {
            // 결재 문서에는 상신(SB)/승인(AP)만 (반려·재상신 제외)
            return ["SB", "AP"].indexOf(h.Action) >= 0;
          })
          .map(
            function (h) {
              return (
                "<tr>" +
                "<td>" +
                this._esc(h.Seqnr) +
                "</td>" +
                "<td>" +
                this._esc(this.fmtActionText(h.Action)) +
                "</td>" +
                "<td>" +
                this._esc(h.Ename) +
                "</td>" +
                "<td>" +
                this._esc(h.Zgrade) +
                "</td>" +
                "<td>" +
                this._esc(this.fmtDate(h.Actdt)) +
                "</td>" +
                "<td>" +
                this._esc(h.ApprComment) +
                "</td>" +
                "</tr>"
              );
            }.bind(this),
          )
          .join("");

        // 결재란 (상단 우측 도장 박스) - 공식 결재 흐름(상신/승인)만
        var aAppr = aHistory.filter(function (h) {
          return ["SB", "AP"].indexOf(h.Action) >= 0;
        });
        var sApprCells = aAppr
          .map(
            function (h) {
              var sRole = this.fmtActionText(h.Action);
              var sCls =
                h.Action === "AP" ? "ap" : h.Action === "RJ" ? "rj" : "sb";
              var sP = this._sealPernr(h.Pernr);
              var sImgUrl = (this._mSealImg && this._mSealImg[sP]) || "";
              var sInner = sImgUrl
                ? '<img class="appimg" src="' + sImgUrl + '"/>'
                : this._sealFrameSvg("appframe") +
                  '<b class="appname">' +
                  (h.Ename || "")
                    .split("")
                    .map(
                      function (c) {
                        return "<i>" + this._esc(c) + "</i>";
                      }.bind(this),
                    )
                    .join("") +
                  "</b>";

              return (
                '<td class="appcell">' +
                '<div class="approle">' +
                this._esc(sRole) +
                "</div>" +
                '<div class="appsign ' +
                sCls +
                '">' +
                '<span class="appstamp ' +
                sCls +
                (sImgUrl ? " hasimg" : "") +
                '">' +
                sInner +
                "</span>" +
                "</div>" +
                '<div class="appmeta">' +
                this._esc((h.Zgrade || "") + " · " + this.fmtDate(h.Actdt)) +
                "</div>" +
                "</td>"
              );
            }.bind(this),
          )
          .join("");
        if (!sApprCells) {
          sApprCells =
            '<td class="appcell"><div class="approle">결재</div><div class="appsign"></div><div class="appmeta">-</div></td>';
        }
        var sApprovalBox =
          '<table class="apprbox"><tr>' + sApprCells + "</tr></table>";

        var sWaersDisp = (sWaers || "").trim() || "KRW";

        // 구매사유: 아이템(PR)들의 고유 사유 집계
        var oSeenR = {};
        var aReasonCodes = [];
        aItems.forEach(function (it) {
          var c = (it.Purrsn || "").trim();
          if (c && !oSeenR[c]) {
            oSeenR[c] = true;
            aReasonCodes.push(c);
          }
        });
        var sReasonHtml;
        if (!aReasonCodes.length) {
          sReasonHtml = "<strong>구매 사유 없음</strong>";
        } else if (aReasonCodes.length === 1) {
          sReasonHtml =
            "<strong>" +
            this._esc(this.fmtReason(aReasonCodes[0])) +
            "</strong>";
        } else {
          sReasonHtml =
            "<strong>복합 사유 (" +
            aReasonCodes.length +
            "건)</strong><br/>" +
            this._esc(aReasonCodes.map(this.fmtReason.bind(this)).join(" · "));
        }

        var sToday = this.fmtDate(
          new Date().toISOString().slice(0, 10).replace(/-/g, ""),
        );

        var nGrand = Math.round(nTotal);
        var nItemCnt = aItems.length;

        // 최단 납기일 (납기 요약)
        var sMinLfdat = "";
        aItems.forEach(function (o) {
          if (o.Lfdat && (!sMinLfdat || o.Lfdat < sMinLfdat)) {
            sMinLfdat = o.Lfdat;
          }
        });

        var sStatuTxt = this.fmtPlainStatu(oData.Statu);

        var sBody =
          '<div class="doc">' +
          // 레터헤드
          '<div class="letterhead">' +
          '<div class="company">태산자전거 <span class="company-en">TAESAN BICYCLE</span></div>' +
          '<div class="docmeta">문서번호 ' +
          this._esc(oData.Ebeln) +
          "<br/>발행일자 " +
          this._esc(sToday) +
          "</div>" +
          "</div>" +
          // 제목 + 결재란
          '<div class="titlerow">' +
          '<h1 class="doctitle">구 매 오 더 결 재 서</h1>' +
          sApprovalBox +
          "</div>" +
          // 품의 개요 (요약 문장)
          '<div class="abstract">아래와 같이 구매오더 <b>' +
          this._esc(oData.Ebeln) +
          "</b> 건(총 " +
          nItemCnt +
          "개 품목, 합계 <b>" +
          this._esc(this.fmtNumber(nGrand) + " " + sWaersDisp) +
          "</b>)을 발주하고자 결재를 요청합니다." +
          "</div>" +
          // 기본 정보
          '<div class="section"><div class="sech">1. 기본 정보</div>' +
          '<table class="kv">' +
          "<tr>" +
          "<th>구매오더번호</th><td>" +
          this._esc(oData.Ebeln) +
          "</td>" +
          "<th>구매오더유형</th><td>" +
          this._esc(this.fmtBsart(oData.Bsart)) +
          "</td>" +
          "</tr><tr>" +
          "<th>공급업체</th><td>" +
          this._esc(this.fmtVendor(oData.Lifnr, oData.Name1)) +
          "</td>" +
          "<th>플랜트</th><td>" +
          this._esc(oData.Werks) +
          "</td>" +
          "</tr><tr>" +
          "<th>상신자</th><td>" +
          this._esc(this._submitterFromHistory(aHistory, oData.Ernam)) +
          "</td>" +
          "<th>구매오더생성일</th><td>" +
          this._esc(this.fmtDate(oData.Bedat)) +
          "</td>" +
          "</tr><tr>" +
          "<th>통화</th><td>" +
          this._esc(sWaersDisp) +
          "</td>" +
          "<th>최단 납기일</th><td>" +
          this._esc(sMinLfdat ? this.fmtDate(sMinLfdat) : "-") +
          "</td>" +
          "</tr><tr>" +
          '<th>결재상태</th><td><span class="badge badge-' +
          this._esc(oData.Statu) +
          '">' +
          this._esc(sStatuTxt) +
          "</span></td>" +
          "<th>품목 수</th><td>" +
          nItemCnt +
          " 건</td>" +
          "</tr>" +
          "</table></div>" +
          // 구매 사유
          '<div class="section"><div class="sech">2. 구매 사유</div>' +
          '<div class="reason">' +
          sReasonHtml +
          "</div></div>" +
          // 품목 내역
          '<div class="section"><div class="sech">3. 품목 내역</div>' +
          '<table class="data"><thead><tr><th class="c">품목</th><th>자재번호</th><th>자재명</th><th class="num">발주수량</th><th class="num">단가</th><th class="num">금액</th><th class="c">납기일</th><th class="c">PR번호</th></tr></thead><tbody>' +
          (sItemRows ||
            '<tr><td colspan="8" class="empty">품목 없음</td></tr>') +
          "</tbody></table>" +
          // 금액 요약 (합계)
          '<table class="amt">' +
          '<tr class="grand"><th>합계 금액</th><td class="num">' +
          this._esc(this.fmtNumber(nGrand) + " " + sWaersDisp) +
          "</td></tr>" +
          "</table></div>" +
          // 결재 이력
          '<div class="section"><div class="sech">4. 결재 이력</div>' +
          '<table class="data"><thead><tr><th class="c">순번</th><th class="c">처리</th><th>처리자</th><th class="c">직급</th><th class="c">처리일시</th><th>의견</th></tr></thead><tbody>' +
          (sHistoryRows ||
            '<tr><td colspan="6" class="empty">이력 없음</td></tr>') +
          "</tbody></table></div>" +
          '<div class="foot">본 문서는 시스템에서 자동 생성된 구매오더 결재서입니다. &nbsp;|&nbsp; 태산자전거 구매관리시스템 &nbsp;|&nbsp; 출력일 ' +
          this._esc(sToday) +
          "</div>" +
          "</div>";

        this._sPdfStyle =
          "*{box-sizing:border-box;}" +
          'body{font-family:"Malgun Gothic","맑은 고딕",Arial,sans-serif;color:#222;margin:0;background:#e7e9ee;-webkit-print-color-adjust:exact;print-color-adjust:exact;}' +
          ".doc{position:relative;background:#fff;max-width:820px;margin:0 auto;padding:50px 54px 44px;}" +
          // 레터헤드
          ".letterhead{display:flex;justify-content:space-between;align-items:flex-end;border-bottom:2.5px solid #1a3a5c;padding-bottom:10px;}" +
          ".company{font-size:17px;font-weight:800;color:#1a3a5c;letter-spacing:0.5px;}" +
          ".company-en{font-size:10px;font-weight:600;color:#9aa7b4;letter-spacing:2px;margin-left:6px;}" +
          ".docmeta{text-align:right;font-size:10.5px;color:#5a6b7b;line-height:1.6;}" +
          // 제목 + 결재란
          ".titlerow{display:flex;justify-content:space-between;align-items:center;margin:26px 0 22px;}" +
          ".doctitle{margin:0;font-size:26px;font-weight:800;letter-spacing:6px;color:#16222f;border-bottom:3px double #1a3a5c;padding-bottom:8px;}" +
          // 결재란 도장 박스
          ".apprbox{border-collapse:collapse;}" +
          ".apprbox td.appcell{border:1px solid #9aa7b4;width:74px;padding:0;text-align:center;vertical-align:top;}" +
          ".approle{font-size:9.5px;font-weight:700;color:#46586a;background:#eef2f6;border-bottom:1px solid #cdd6e0;padding:3px 0;}" +
          ".appsign{height:50px;display:flex;align-items:center;justify-content:center;}" +
          ".appstamp{position:relative;display:inline-flex;align-items:center;justify-content:center;width:46px;height:46px;color:#b3261e;transform:rotate(-4deg);}" +
          ".appframe{position:absolute;top:0;left:0;width:100%;height:100%;}" +
          ".appname{position:relative;z-index:1;display:flex;flex-direction:column;align-items:center;justify-content:center;line-height:1;font-weight:900;}" +
          ".appname i{font-style:normal;font-size:12.5px;font-family:'Batang','Gungsuh',serif;letter-spacing:-0.5px;}" +
          ".appimg{position:absolute;top:0;left:0;width:100%;height:100%;object-fit:contain;z-index:3;}" +
          ".appstamp.ap{color:#b3261e;}.appstamp.rj{color:#7a1f1a;}.appstamp.sb{color:#1a3a6b;}" +
          ".appmeta{font-size:8px;color:#7a8794;border-top:1px solid #e0e6ee;padding:3px 2px;}" +
          // 섹션
          ".section{margin-top:20px;}" +
          ".sech{font-size:13px;font-weight:800;color:#1a3a5c;margin-bottom:7px;padding-left:2px;}" +
          // KV 정보표
          "table.kv{width:100%;border-collapse:collapse;font-size:12px;border-top:2px solid #1a3a5c;}" +
          "table.kv th{width:15%;background:#f1f4f8;color:#3d4d5d;font-weight:700;text-align:left;padding:9px 12px;border:1px solid #d9e0e8;}" +
          "table.kv td{width:35%;padding:9px 12px;border:1px solid #d9e0e8;color:#1f2c39;font-weight:600;}" +
          "table.kv .totl{background:#fbf3e8;color:#b3650a;font-weight:900;}" +
          ".badge{display:inline-block;padding:2px 10px;border-radius:3px;font-size:11px;font-weight:800;border:1px solid;}" +
          ".badge-AP{background:#eaf7ee;color:#1d7a33;border-color:#bfe3c8;}" +
          ".badge-RJ{background:#fdeced;color:#c0392b;border-color:#f3c2c5;}" +
          ".badge-FT,.badge-PD{background:#eaf4ff;color:#0a5aa8;border-color:#cfe5ff;}" +
          ".badge-SV{background:#fff6e5;color:#b9770a;border-color:#f3dca6;}" +
          // 사유
          ".reason{border:1px solid #e3d9c4;border-left:4px solid #d8a04a;background:#fdfaf3;padding:13px 16px;font-size:12px;line-height:1.7;color:#5a4a30;}" +
          ".reason strong{color:#a85f10;}" +
          // 데이터표
          "table.data{width:100%;border-collapse:collapse;font-size:11px;border-top:2px solid #1a3a5c;}" +
          "table.data th{background:#f1f4f8;color:#3d4d5d;padding:8px 9px;text-align:left;font-weight:700;border:1px solid #d9e0e8;}" +
          "table.data td{padding:7px 9px;border:1px solid #e3e9f0;color:#2a3744;}" +
          "table.data tbody tr:nth-child(even) td{background:#fafbfd;}" +
          "table.data .sumrow td{background:#f1f4f8 !important;font-weight:800;border-top:2px solid #cdd6e0;}" +
          "table.data .sumrow .totl{color:#b3650a;}" +
          ".num{text-align:right;}.c{text-align:center;}.empty{text-align:center;color:#aab4be;padding:14px;}" +
          // 품의 개요
          ".abstract{margin:18px 0 4px;padding:12px 16px;background:#f5f8fc;border:1px solid #dde6f0;border-radius:4px;font-size:12px;line-height:1.6;color:#2a3744;}" +
          ".abstract b{color:#0a4f90;}" +
          // 금액 요약표
          "table.amt{width:46%;margin:8px 0 0 auto;border-collapse:collapse;font-size:11.5px;}" +
          "table.amt th{background:#f1f4f8;color:#3d4d5d;text-align:left;font-weight:700;padding:7px 12px;border:1px solid #d9e0e8;width:50%;}" +
          "table.amt td{padding:7px 12px;border:1px solid #d9e0e8;font-weight:700;color:#1f2c39;}" +
          "table.amt .grand th{background:#1a3a5c;color:#fff;}table.amt .grand td{background:#fbf3e8;color:#b3650a;font-weight:900;font-size:12.5px;}" +
          // 특기사항
          ".note{border:1px solid #e0e6ee;border-radius:4px;padding:11px 14px;font-size:11.5px;line-height:1.6;color:#46586a;background:#fcfdfe;}" +
          ".foot{margin-top:30px;text-align:center;color:#9aa7b4;font-size:10px;border-top:1px solid #e0e6ee;padding-top:12px;letter-spacing:0.3px;}" +
          // 본문 하단 원형 도장(미사용이지만 클래스 유지)
          ".stamp-wrap{display:flex;gap:16px;}.stamp{display:none;}" +
          "@media print{body{background:#fff;}.doc{margin:0;max-width:none;padding:12mm 14mm;}}";

        this._sPdfBody = sBody;

        return (
          '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>구매오더 결재서 ' +
          this._esc(oData.Ebeln) +
          "</title><style>" +
          this._sPdfStyle +
          "</style></head><body>" +
          sBody +
          "</body></html>"
        );
      },

      _renderPdfPreview: function () {
        if (!this._sSelectedEbeln) {
          return;
        }
        var oModel = this.getOwnerComponent().getModel();
        var sEbeln = this._sSelectedEbeln;

        var pHeader = new Promise(function (resolve, reject) {
          oModel.read("/PoApproval('" + encodeURIComponent(sEbeln) + "')", {
            success: resolve,
            error: reject,
          });
        });
        var pItems = new Promise(function (resolve) {
          oModel.read("/PoItem", {
            filters: [new Filter("Ebeln", FilterOperator.EQ, sEbeln)],
            success: function (o) {
              resolve(o && o.results ? o.results : []);
            },
            error: function () {
              resolve([]);
            },
          });
        });
        var pHistory = new Promise(function (resolve) {
          oModel.read("/PoHistory", {
            filters: [new Filter("Ebeln", FilterOperator.EQ, sEbeln)],
            success: function (o) {
              resolve(o && o.results ? o.results : []);
            },
            error: function () {
              resolve([]);
            },
          });
        });

        Promise.all([pHeader, pItems, pHistory]).then(
          function (a) {
            var oHeader = a[0];
            oHeader.to_Item = { results: a[1] };
            oHeader.to_History = { results: a[2] };

            this._preloadSeals(a[2]).then(
              function () {
                this._buildPdfHtml(oHeader);
                var oBox = document.getElementById("pdfPreviewBox");
                if (oBox) {
                  oBox.innerHTML =
                    "<style>" + this._sPdfStyle + "</style>" + this._sPdfBody;
                }
              }.bind(this),
            );
          }.bind(this),
        );
      },

      _readStartupEbeln: function () {
        var sHref = window.location.href || "";
        var aMatch = sHref.match(/[?&]ebeln=([^&]+)/i);

        if (aMatch && aMatch[1]) {
          return decodeURIComponent(aMatch[1]);
        }

        return null;
      },

      _openStartupDetail: function () {
        var sEbeln = this._sStartupEbeln;

        if (!sEbeln) {
          return;
        }

        this._sStartupEbeln = null;

        var oModel = this.getOwnerComponent().getModel();
        var sPath = "/PoApproval('" + encodeURIComponent(sEbeln) + "')";

        oModel.read(sPath, {
          success: function (oData) {
            this._showDetail(oData);
          }.bind(this),
          error: function () {
            MessageToast.show("지정된 PO를 찾을 수 없습니다: " + sEbeln);
          },
        });
      },

      fmtStatuBadge: function (s) {
        var m = {
          SV: { t: "상신대기", cls: "poBadge poBadge--wait" },
          FT: { t: "전결", cls: "poBadge poBadge--fast" },
          PD: { t: "일반결재", cls: "poBadge poBadge--progress" },
          AP: { t: "승인완료", cls: "poBadge poBadge--approved" },
          RJ: { t: "반려", cls: "poBadge poBadge--rejected" },
        };

        var o = m[s] || { t: s || "-", cls: "poBadge" };
        return '<span class="' + o.cls + '">' + this._esc(o.t) + "</span>";
      },

      fmtPlainStatu: function (s) {
        return (
          {
            SV: "상신대기",
            FT: "전결",
            PD: "일반결재",
            AP: "승인완료",
            RJ: "반려",
          }[s] ||
          s ||
          "-"
        );
      },

      fmtApprType: function (s) {
        return (
          {
            FT: "전결",
            PD: "일반결재",
            AP: "승인완료",
            RJ: "반려",
            SV: "상신대기",
          }[s] || "-"
        );
      },

      fmtComment: function (s) {
        if (!s) return "";
        // 결재유형 코드 → 한글 (코멘트에 "FT 승인", "PD 상신" 등으로 저장된 경우)
        s = s.replace(/\bFT\b/g, "전결").replace(/\bPD\b/g, "일반결재");
        // 코멘트 내 "16425000.00" 형태 금액의 소수점 제거 + 천단위 콤마
        return s.replace(/(\d[\d,]*)\.(\d{2})\b/g, function (m, intPart) {
          var n = Number(intPart.replace(/,/g, ""));
          if (isNaN(n)) return m;
          return n.toLocaleString("ko-KR");
        });
      },

      fmtReason: function (sCode) {
        if (!sCode) return "-";
        return (
          {
            MRP: "MRP 부족분 보충",
            URGENT: "긴급 구매 요청",
            STOCK: "안전재고/재주문점 보충",
            NEWITEM: "신규 품목 도입",
            REPLACE: "노후/불량 자재 교체",
            ETC: "기타구매",
          }[sCode] || sCode
        );
      },

      fmtVendor: function (sLifnr, sName1) {
        if (!sLifnr) return "공급업체 -";
        var sName = (sName1 || "").trim();
        return sName ? sLifnr + " / " + sName : sLifnr;
      },

      fmtStatuPlain: function (s) {
        return (
          {
            AP: "승인 완료",
            RJ: "반려",
            FT: "결재 대기",
            PD: "결재 대기",
            ING: "결재 대기",
          }[s] || "-"
        );
      },

      fmtVendorName: function (sLifnr, sName1) {
        var sName = (sName1 || "").trim();
        return sName || sLifnr || "공급업체 -";
      },

      fmtInitial: function (sLifnr, sName1) {
        var s = (sName1 || "").trim().replace(/^[㈜()주\s]+/, "");
        if (!s) return (sLifnr || "PO").slice(0, 2);
        return s.slice(0, 1);
      },

      fmtBsart: function (s) {
        if (!s) return "-";
        return (
          {
            NB: "일반구매",
            UB: "긴급구매",
            ZMRP: "MRP구매",
            ZNB: "일반구매",
          }[s] || s
        );
      },

      fmtActionText: function (s) {
        return (
          {
            SB: "상신",
            RS: "재상신",
            AP: "승인",
            RJ: "반려",
          }[s] ||
          s ||
          "-"
        );
      },

      fmtInitials: function (s) {
        return s ? s.charAt(0) : "?";
      },

      fmtPlant: function (sWerks) {
        return sWerks ? "PLANT " + sWerks : "PLANT";
      },

      fmtAmountText: function (v1, v2, v3, sWaers) {
        var v = v1 || v2 || v3;
        var sCurrency = (sWaers || "").trim() || "KRW";
        var n = Number(v);

        if (v === undefined || v === null || v === "" || isNaN(n) || n === 0) {
          return "총 금액 -";
        }

        return (
          "총 금액 " + this.fmtNumber(Math.round(n * 100)) + " " + sCurrency
        );
      },

      fmtNumber: function (v) {
        var n = Number(v);

        if (isNaN(n)) {
          return String(v || "");
        }

        return n.toLocaleString("ko-KR");
      },

      fmtDate: function (v) {
        if (!v) {
          return "";
        }

        if (v instanceof Date) {
          return (
            v.getFullYear() +
            "-" +
            String(v.getMonth() + 1).padStart(2, "0") +
            "-" +
            String(v.getDate()).padStart(2, "0")
          );
        }

        if (typeof v === "string" && v.indexOf("/Date") >= 0) {
          var ms = parseInt(v.replace(/\/Date\((\d+)[^)]*\)\//, "$1"), 10);
          var d = new Date(ms);

          return (
            d.getFullYear() +
            "-" +
            String(d.getMonth() + 1).padStart(2, "0") +
            "-" +
            String(d.getDate()).padStart(2, "0")
          );
        }

        var s = String(v);

        if (s.length === 8) {
          return (
            s.substring(0, 4) +
            "-" +
            s.substring(4, 6) +
            "-" +
            s.substring(6, 8)
          );
        }

        return s.substring(0, 10);
      },

      _getAmountValue: function (oData) {
        return (
          oData.TotalAmount ||
          oData.TotalAmt ||
          oData.TOTAL_AMT ||
          oData.Netwr ||
          oData.Dmbtr ||
          oData.Wrbtr ||
          ""
        );
      },

      _getNavResults: function (vNav) {
        if (!vNav) {
          return [];
        }

        if (Array.isArray(vNav)) {
          return vNav;
        }

        if (vNav.results) {
          return vNav.results;
        }

        return [];
      },

      _minDeliveryDate: function (aItems) {
        var oMin = null;
        (aItems || []).forEach(function (it) {
          var v = it.Lfdat;
          if (v === undefined || v === null || v === "") return;
          var key = v instanceof Date ? v.getTime() : String(v);
          if (oMin === null || key < oMin.key) {
            oMin = { key: key, raw: v };
          }
        });
        return oMin ? this.fmtDate(oMin.raw) : "";
      },

      onItemSearch: function (oEvent) {
        var sQuery = (oEvent.getParameter("newValue") || "").trim();
        var oBinding = this.byId("itemTableMain").getBinding("items");
        if (!oBinding) return;
        // 검색 중에는 헤더 금액/사유 고정 (요약 카드만 갱신)
        this._bItemFilter = true;
        if (!sQuery) {
          oBinding.filter([]);
          return;
        }
        oBinding.filter([
          new Filter({
            filters: [
              new Filter("Maktx", FilterOperator.Contains, sQuery),
              new Filter("Matnr", FilterOperator.Contains, sQuery),
              new Filter("Ebelp", FilterOperator.Contains, sQuery),
            ],
            and: false,
          }),
        ]);
      },

      _calcTotal: function (aItems) {
        var nTotal = 0;

        (aItems || []).forEach(function (o) {
          var nQty = Number(o.Menge) || 0;
          var nPrice = Number(o.Netpr) || 0;
          nTotal += nQty * nPrice;
        });

        return nTotal;
      },

      _parseErr: function (e) {
        try {
          return JSON.parse(e.responseText).error.message.value;
        } catch (err) {
          return e.message || "오류";
        }
      },

      _esc: function (v) {
        return String(v == null ? "" : v)
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;");
      },
    });
  },
);
