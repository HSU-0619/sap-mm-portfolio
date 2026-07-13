sap.ui.define(
  [
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter",
    "sap/m/ColumnListItem",
    "sap/m/Text",
    "sap/m/ObjectNumber",
    "sap/ui/core/HTML",
    "sap/m/ActionSheet",
    "sap/m/Button",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/BusyDialog",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "c1/mm/c1mmqr/util/CameraScanner",
  ],
  function (
    Controller,
    Filter,
    FilterOperator,
    Sorter,
    ColumnListItem,
    Text,
    ObjectNumber,
    HTML,
    ActionSheet,
    Button,
    MessageToast,
    MessageBox,
    BusyDialog,
    SelectDialog,
    StandardListItem,
    CameraScanner,
  ) {
    "use strict";

    return Controller.extend("c1.mm.c1mmqr.controller.qrView", {
      _oSelectedData: null,
      _sSortField: "Bldat",
      _bSortDesc: true,
      _iQrSeq: 0, // QR 렌더 순번 (늦게 도착한 이전 렌더 무시용)

      // 배포된 앱 주소 — QR에 이 URL이 인코딩됨 (핸드폰으로 찍으면 재고조회 직행)
      // SAP HTTPS(44300) → 폰 인앱 카메라 동작 (사내망 접속 필요)
      QR_BASE_URL:
        "https://61.97.134.34:44300/sap/bc/ui5_ui5/sap/zc1mmqr/index.html",

      _buildQrUrl: function (sQrNo) {
        return this.QR_BASE_URL + "#/scan/" + encodeURIComponent(sQrNo);
      },

      onInit: function () {
        var oRouter = this.getOwnerComponent().getRouter();
        oRouter
          .getRoute("RouteqrView")
          .attachPatternMatched(this._onRoute, this);
        oRouter
          .getRoute("RouteqrScanDirect")
          .attachPatternMatched(this._onRouteScanDirect, this);

        // 스캔 탭의 "창고 현황에서 보기" → 창고 현황 탭 + 자재 조회
        this.getOwnerComponent()
          .getEventBus()
          .subscribe(
            "qr",
            "viewMaterial",
            function (ch, ev, data) {
              var sMatnr = (data && data.matnr) || "";
              this.byId("mainTabs").setSelectedKey("lookup");
              if (!sMatnr) {
                return;
              }
              this.byId("inDashQuery").setValue(sMatnr);
              // 탭 렌더 완료 후 조회 (이미지 등 렌더 타이밍 보정)
              setTimeout(
                function () {
                  this._dashLookup(sMatnr);
                }.bind(this),
                60,
              );
            },
            this,
          );

        // 모바일(폰): 발행관리 숨기고 [창고 현황 + QR 스캔] 전용
        if (sap.ui.Device.system.phone) {
          this.byId("tabIssue").setVisible(false);
          this.byId("btnNavHist").setVisible(false);
          this.byId("mainTabs").setSelectedKey("scan");
        }
      },

      onMainTabSelect: function () {},

      _onRoute: function () {
        this._loadList();
      },

      // QR 링크(#/scan/QR번호)로 진입 → QR 스캔 탭 (임베드된 스캔뷰가 자동 조회)
      _onRouteScanDirect: function () {
        this._loadList();
        this.byId("mainTabs").setSelectedKey("scan");
      },

      // ── 필터 ───────────────────────────────────────────────

      _buildFilters: function () {
        var aFilters = [];

        var sMatnr = this.byId("sfMatnr").getValue().trim();
        var sEbeln = this.byId("sfEbeln").getValue().trim();
        var sMblnr = this.byId("sfMblnr").getValue().trim();
        var sCharg = this.byId("sfCharg").getValue().trim();
        var sStatus = this.byId("selQrStatus").getSelectedKey();
        var dFrom = this.byId("dpFrom").getDateValue();
        var dTo = this.byId("dpTo").getDateValue();

        if (sMatnr)
          aFilters.push(new Filter("Matnr", FilterOperator.Contains, sMatnr));
        if (sEbeln)
          aFilters.push(new Filter("Ebeln", FilterOperator.Contains, sEbeln));
        if (sMblnr)
          aFilters.push(new Filter("Mblnr", FilterOperator.Contains, sMblnr));
        if (sCharg)
          aFilters.push(new Filter("Charg", FilterOperator.Contains, sCharg));
        if (sStatus === "X") {
          aFilters.push(new Filter("QrIssued", FilterOperator.EQ, "X"));
        } else if (sStatus === "NONE") {
          aFilters.push(new Filter("QrIssued", FilterOperator.EQ, ""));
        }
        if (dFrom) aFilters.push(new Filter("Bldat", FilterOperator.GE, dFrom));
        if (dTo) aFilters.push(new Filter("Bldat", FilterOperator.LE, dTo));

        return aFilters;
      },

      _toEdmDate: function (sYyyymmdd) {
        if (!sYyyymmdd || sYyyymmdd.length < 8) return null;
        var y = parseInt(sYyyymmdd.substring(0, 4), 10);
        var m = parseInt(sYyyymmdd.substring(4, 6), 10) - 1;
        var d = parseInt(sYyyymmdd.substring(6, 8), 10);
        return new Date(y, m, d);
      },

      // ── 목록 조회 ──────────────────────────────────────────

      _loadList: function () {
        var oTable = this.byId("qrTargetTable");
        if (!oTable) return;

        var aFilters = this._buildFilters();
        var oSorter = new Sorter(this._sSortField, this._bSortDesc);

        oTable.setBusy(true);
        oTable.unbindItems();

        oTable.bindItems({
          path: "/QrTarget",
          filters: aFilters,
          sorter: oSorter,
          template: this._getTableTemplate(),
          templateShareable: false,
          events: {
            dataReceived: function (oEvent) {
              oTable.setBusy(false);
              var oData = oEvent.getParameter("data");
              if (oData && oData.error) {
                MessageToast.show("목록 조회 중 오류가 발생했습니다.");
              }
              var nCnt = oTable.getItems().length;
              this.byId("listSubHeader").setText(nCnt + "건 조회됨");
              this.byId("btnBulkIssue").setEnabled(false);

              // 발행완료(QrIssued=X) 건은 일괄발행 대상에서 제외 → 체크박스 비활성
              // (재발행은 행 더블클릭 → 우측 상세 화면에서만 가능)
              oTable.getItems().forEach(function (oItem) {
                var oCtx = oItem.getBindingContext();
                if (!oCtx) return;
                var bIssued = oCtx.getProperty("QrIssued") === "X";
                oItem.setSelected(false);
                if (oItem.setSelectable) {
                  oItem.setSelectable(!bIssued);
                }
                if (bIssued) {
                  oItem.addStyleClass("qrNoChk"); // 체크박스 칸 자체 숨김
                } else {
                  oItem.removeStyleClass("qrNoChk");
                }
              });
            }.bind(this),
          },
        });
      },

      _getTableTemplate: function () {
        var that = this;
        return new ColumnListItem({
          type: "Active",
          press: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext();
            if (oCtx) that._showDetail(oCtx.getObject());
          },
          cells: [
            new Text({ text: "{Matnr}", wrapping: false }),
            new Text({ text: "{Maktx}" }), // 자재명만 줄바꿈 허용
            new Text({ text: "{Charg}", wrapping: false }),
            new ObjectNumber({
              number: { path: "Menge", formatter: that.fmtQty },
              unit: "{Meins}",
            }),
            new Text({
              // 최신 입고일: 증빙일(Bldat=입고 등록일) 우선, 없으면 전기일(Budat)
              text: {
                parts: ["Bldat", "Budat"],
                formatter: function (bldat, budat) {
                  return that.fmtDate(bldat || budat);
                },
              },
              wrapping: false,
            }),
            new HTML({
              content: {
                path: "QrIssued",
                formatter: that.fmtQrBadge.bind(that),
              },
              preferDOM: false,
            }),
          ],
        });
      },

      onSearch: function () {
        this._loadList();
        this._hideDetail();
      },

      // ── 조회조건 서치헬프 (현재 데이터 기준 distinct) ──────────
      onVHMatnr: function () {
        this._openVH("Matnr", "sfMatnr", "자재번호");
      },

      // 창고 현황: 자재번호+자재명 서치헬프 — 현재고(BatchStock) 있는 자재만, 이름은 QrTarget에서
      onVHDashMatnr: function () {
        var that = this;
        var oModel = this.getOwnerComponent().getModel();
        // 1) 자재명 매핑 (QrTarget: Matnr→Maktx)
        oModel.read("/QrTarget", {
          urlParameters: { $top: 5000 },
          success: function (oQt) {
            var mName = {};
            (oQt.results || []).forEach(function (r) {
              if (r.Matnr && !mName[r.Matnr]) {
                mName[r.Matnr] = r.Maktx || "";
              }
            });
            // 2) 현재 재고 있는 자재만 (BatchStock distinct Matnr)
            oModel.read("/BatchStock", {
              urlParameters: { $top: 5000 },
              success: function (oBs) {
                var seen = {},
                  items = [];
                (oBs.results || []).forEach(function (r) {
                  var v = (r.Matnr || "").toString().trim();
                  if (v && !seen[v]) {
                    seen[v] = true;
                    items.push({ text: v, info: mName[v] || "" });
                  }
                });
                items.sort(function (a, b) {
                  return a.text < b.text ? -1 : 1;
                });
                that._openMatVHDialog(items);
              },
              error: function () {
                MessageToast.show("서치헬프 조회 실패");
              },
            });
          },
          error: function () {
            MessageToast.show("서치헬프 조회 실패");
          },
        });
      },

      _openMatVHDialog: function (items) {
        var that = this;
        var dlg = new SelectDialog({
          title: "자재 선택",
          noDataText: "데이터가 없습니다.",
          search: function (e) {
            var s = e.getParameter("value");
            e.getSource()
              .getBinding("items")
              .filter(
                s
                  ? [
                      new Filter({
                        filters: [
                          new Filter("text", FilterOperator.Contains, s),
                          new Filter("info", FilterOperator.Contains, s),
                        ],
                        and: false,
                      }),
                    ]
                  : [],
              );
          },
          confirm: function (e) {
            var sel = e.getParameter("selectedItem");
            if (sel) {
              that.byId("inDashQuery").setValue(sel.getTitle());
              that.onDashSearch();
            }
            dlg.destroy();
          },
          cancel: function () {
            dlg.destroy();
          },
        });
        dlg.setModel(new sap.ui.model.json.JSONModel({ items: items }));
        dlg.bindAggregation("items", {
          path: "/items",
          template: new StandardListItem({
            title: "{text}",
            description: "{info}",
          }),
        });
        this.getView().addDependent(dlg);
        dlg.open();
      },

      onVHEbeln: function () {
        this._openVH("Ebeln", "sfEbeln", "구매오더번호");
      },
      onVHMblnr: function () {
        this._openVH("Mblnr", "sfMblnr", "자재문서번호");
      },
      onVHCharg: function () {
        this._openVH("Charg", "sfCharg", "배치번호");
      },

      _openVH: function (sField, sInputId, sTitle) {
        var oModel = this.getOwnerComponent().getModel();
        var that = this;
        oModel.read("/QrTarget", {
          urlParameters: { $top: 5000 },
          success: function (oData) {
            var aRows = oData.results || [];
            var oSeen = {};
            var aItems = [];
            aRows.forEach(function (r) {
              var v = (r[sField] || "").toString().trim();
              if (v && !oSeen[v]) {
                oSeen[v] = true;
                aItems.push({
                  text: v,
                  info: sField === "Matnr" ? r.Maktx || "" : r.Matnr || "",
                });
              }
            });
            aItems.sort(function (a, b) {
              return a.text < b.text ? -1 : 1;
            });

            var oVHModel = new sap.ui.model.json.JSONModel({ items: aItems });
            var oDialog = new SelectDialog({
              title: sTitle,
              noDataText: "데이터가 없습니다.",
              search: function (oEvt) {
                var s = oEvt.getParameter("value");
                oEvt
                  .getSource()
                  .getBinding("items")
                  .filter(
                    s ? [new Filter("text", FilterOperator.Contains, s)] : [],
                  );
              },
              confirm: function (oEvt) {
                var oSel = oEvt.getParameter("selectedItem");
                if (oSel) {
                  that.byId(sInputId).setValue(oSel.getTitle());
                }
                oDialog.destroy();
              },
              cancel: function () {
                oDialog.destroy();
              },
            });
            oDialog.setModel(oVHModel);
            oDialog.bindAggregation("items", {
              path: "/items",
              template: new StandardListItem({
                title: "{text}",
                description: "{info}",
              }),
            });
            that.getView().addDependent(oDialog);
            oDialog.open();
          },
          error: function () {
            MessageToast.show("서치헬프 조회 실패");
          },
        });
      },

      onReset: function () {
        this.byId("sfMatnr").setValue("");
        this.byId("sfEbeln").setValue("");
        this.byId("sfMblnr").setValue("");
        this.byId("sfCharg").setValue("");
        this.byId("selQrStatus").setSelectedKey("ALL");
        this.byId("dpFrom").setValue("");
        this.byId("dpTo").setValue("");
        this._loadList();
        this._hideDetail();
      },

      // ── 선택 / 상세 ────────────────────────────────────────

      onSelectionChange: function () {
        var oTable = this.byId("qrTargetTable");
        // 발행완료 건이 선택되면(전체선택 등) 즉시 해제 → 미발행만 카운트
        var nSel = 0;
        oTable.getSelectedItems().forEach(function (oItem) {
          var oCtx = oItem.getBindingContext();
          if (oCtx && oCtx.getProperty("QrIssued") === "X") {
            oItem.setSelected(false);
            return;
          }
          nSel++;
        });
        this.byId("btnBulkIssue").setEnabled(nSel > 1);
      },

      onRowPress: function (oEvent) {
        var oCtx = oEvent.getSource().getBindingContext();
        if (!oCtx) return;
        this._showDetail(oCtx.getObject());
      },

      _showDetail: function (oData) {
        this._oSelectedData = oData;

        this.byId("emptyDetail").setVisible(false);
        this.byId("detailPanel").setVisible(true);

        this.byId("dMatnr").setText(oData.Matnr || "");
        this.byId("dMaktx").setText(oData.Maktx || "");
        this.byId("dStatusBadge").setContent(this.fmtQrBadge(oData.QrIssued));
        this.byId("dLgort").setText("저장위치: " + (oData.Lgort || "-"));
        this.byId("dBudat").setText(
          "최신 입고일: " + this.fmtDate(oData.Bldat || oData.Budat),
        );
        this.byId("dMenge").setText(
          "총수량 " + this.fmtQty(oData.Menge) + " " + (oData.Meins || ""),
        );
        this.byId("dEbeln").setText(oData.Ebeln || "");
        this.byId("dMblnr").setText(oData.Mblnr || "");
        this.byId("dCharg").setText(oData.Charg || "");
        this.byId("dVenName").setText(oData.VenName || "");

        var bIssued = oData.QrIssued === "X";
        this.byId("btnIssueQr").setVisible(!bIssued);
        this.byId("btnReIssue").setVisible(bIssued);

        if (bIssued && oData.QrNo) {
          this.byId("qrNoText").setText("QR번호: " + oData.QrNo);
          this._renderQrCode(oData.QrNo);
        } else {
          this.byId("qrNoText").setText("미발행 상태");
          this._clearQrCode();
        }

        this._loadGrHistSummary(oData);
      },

      // 발행관리 상세: 입고 요약(건수 · 누적 · 기간) — 상세 표는 재고조회
      _loadGrHistSummary: function (oData) {
        var oCnt = this.byId("dGrCount"),
          oSum = this.byId("dGrSum"),
          oPer = this.byId("dGrPeriod");
        oCnt.setText("-");
        oSum.setText("-");
        oPer.setText("-");
        if (!oData.Charg) {
          return;
        }

        var oModel = this.getOwnerComponent().getModel();
        oModel.read("/BatchHist", {
          filters: [
            new Filter("Charg", FilterOperator.EQ, oData.Charg),
            new Filter("Matnr", FilterOperator.EQ, oData.Matnr),
            new Filter({
              filters: [
                new Filter("Bwart", FilterOperator.EQ, "101"),
                new Filter("Bwart", FilterOperator.EQ, "131"),
              ],
              and: false,
            }),
          ],
          sorters: [new Sorter("Budat", false)],
          success: function (oResult) {
            var a = (oResult && oResult.results) || [];
            if (!a.length) {
              oCnt.setText("0건");
              oSum.setText("0");
              oPer.setText("-");
              return;
            }
            var nSum = 0,
              sMeins = "";
            a.forEach(function (r) {
              nSum += parseFloat(r.Menge || 0);
              sMeins = r.Meins || sMeins;
            });
            var aDates = a
              .map(function (r) {
                return r.Bldat || r.Budat;
              })
              .filter(Boolean);
            oCnt.setText(a.length + "건");
            oSum.setText(this.fmtQty(nSum) + " " + sMeins);
            if (aDates.length) {
              var aTimes = aDates.map(function (d) {
                return new Date(d).getTime();
              });
              var dMin = aDates[aTimes.indexOf(Math.min.apply(null, aTimes))];
              var dMax = aDates[aTimes.indexOf(Math.max.apply(null, aTimes))];
              oPer.setText(this.fmtDate(dMin) + " ~ " + this.fmtDate(dMax));
            } else {
              oPer.setText("-");
            }
          }.bind(this),
          error: function () {
            /* BatchHist 미연동 시 - 유지 */
          },
        });
      },

      // 창고별 배치 잔량 요약 문자열 (예: "품질검사창고 29,000 EA")
      _batchStockSummary: function (aRows, sCharg) {
        if (!sCharg) {
          return "-";
        }
        var mB = {};
        aRows.forEach(function (oRow) {
          if ((oRow.Charg || "") !== sCharg) {
            return;
          }
          var k = oRow.Lgort || "";
          if (!mB[k]) {
            mB[k] = { c: 0, i: 0, s: 0, u: 0, m: oRow.Meins };
          }
          mB[k].c += parseFloat(oRow.Clabs || 0);
          mB[k].i += parseFloat(oRow.Cinsm || 0);
          mB[k].s += parseFloat(oRow.Cspem || 0);
          mB[k].u += parseFloat(oRow.Umlme || 0);
        });
        var aParts = Object.keys(mB)
          .sort()
          .map(
            function (k) {
              var o = mB[k];
              var n = o.c + o.i + o.s + o.u;
              return (
                this._lgortName(k) +
                "창고 " +
                this._fmtQty(n) +
                " " +
                (o.m || "")
              );
            }.bind(this),
          );
        return aParts.length ? aParts.join("\n") : "-";
      },

      _hideDetail: function () {
        this._oSelectedData = null;
        this.byId("emptyDetail").setVisible(true);
        this.byId("detailPanel").setVisible(false);
      },

      // ── 입고 이력(누적 내역) 조회 ──────────────────────────

      _loadGrHist: function (oData, sTableId) {
        if (!oData.Charg) return;

        var oModel = this.getOwnerComponent().getModel();
        var oTable = this.byId(sTableId || "grHistTable");
        oTable.destroyItems();

        var aFilters = [
          new Filter("Charg", FilterOperator.EQ, oData.Charg),
          new Filter("Matnr", FilterOperator.EQ, oData.Matnr),
          new Filter({
            filters: [
              new Filter("Bwart", FilterOperator.EQ, "101"),
              new Filter("Bwart", FilterOperator.EQ, "131"),
            ],
            and: false,
          }),
        ];

        oModel.read("/BatchHist", {
          filters: aFilters,
          sorters: [new Sorter("Budat", false), new Sorter("Mblnr", false)],
          success: function (oResult) {
            var aRows = oResult.results || [];
            aRows.forEach(
              function (oRow) {
                oTable.addItem(this._buildGrHistRow(oRow));
              }.bind(this),
            );
            if (aRows.length === 0) {
              oTable.setNoDataText("입고 이력 없음");
            }
          }.bind(this),
          error: function () {
            MessageToast.show("입고 이력 조회 실패");
          },
        });
      },

      // 입고 이력 행 생성 (입고일 · 수량 · 입고문서 · PO/공급업체 · 위치)
      _buildGrHistRow: function (oRow) {
        var sPo = oRow.Ebeln || "-";
        if (oRow.VenName) sPo += " / " + oRow.VenName;
        return new ColumnListItem({
          cells: [
            new Text({
              text: this.fmtDate(oRow.Budat || oRow.Bldat),
              wrapping: false,
            }),
            new ObjectNumber({
              number: "+" + this.fmtQty(oRow.Menge),
              unit: oRow.Meins,
              emphasized: true,
              state: "Success",
            }),
            new Text({ text: oRow.Mblnr || "-", wrapping: false }),
            new Text({ text: sPo }),
            new Text({ text: this._lgortName(oRow.Lgort) }),
          ],
        });
      },

      // ── QR 발행 ────────────────────────────────────────────

      onIssueQr: function () {
        var oData = this._oSelectedData;
        if (!oData) return;

        MessageBox.confirm(
          "자재 " +
            oData.Matnr +
            " [" +
            oData.Mblnr +
            "-" +
            oData.Zeile +
            "] QR을 발행하시겠습니까?",
          {
            title: "QR 발행 확인",
            onClose: function (sAction) {
              if (sAction === MessageBox.Action.OK) {
                this._doIssueQr([oData]);
              }
            }.bind(this),
          },
        );
      },

      onReIssueQr: function () {
        var oData = this._oSelectedData;
        if (!oData) return;

        MessageBox.confirm(
          "QR번호 " +
            oData.QrNo +
            " 을(를) 재발행하시겠습니까?\n(기존 QR은 삭제되고 새 번호로 발행됩니다)",
          {
            title: "QR 재발행 확인",
            onClose: function (sAction) {
              if (sAction === MessageBox.Action.OK) {
                this._doReIssueQr(oData);
              }
            }.bind(this),
          },
        );
      },

      // 재발행 = 기존 QR 삭제 후 새로 발행 (행 중복 방지)
      _doReIssueQr: function (oData) {
        var oModel = this.getOwnerComponent().getModel();
        oModel.setUseBatch(false);

        var sPath = "/QrHist('" + encodeURIComponent(oData.QrNo) + "')";
        var oBusy = new BusyDialog({ text: "기존 QR 삭제 중..." });
        oBusy.open();

        oModel.remove(sPath, {
          success: function () {
            oBusy.close();
            this._doIssueQr([oData]); // 삭제 성공 후 새로 발행
          }.bind(this),
          error: function () {
            oBusy.close();
            MessageBox.error(
              "기존 QR(" + oData.QrNo + ") 삭제에 실패했습니다.",
            );
          },
        });
      },

      onBulkIssue: function () {
        var oTable = this.byId("qrTargetTable");
        var aSelected = oTable.getSelectedItems();
        if (aSelected.length === 0) return;

        var aAll = aSelected.map(function (oItem) {
          return oItem.getBindingContext().getObject();
        });

        // 이미 발행된 건은 제외 (중복 발행 방지)
        var aData = aAll.filter(function (o) {
          return o.QrIssued !== "X";
        });
        var nSkip = aAll.length - aData.length;

        if (aData.length === 0) {
          MessageToast.show("선택한 항목이 모두 이미 발행된 건입니다.");
          return;
        }

        var sMsg = aData.length + "건을 일괄 QR 발행하시겠습니까?";
        if (nSkip > 0) {
          sMsg += "\n(이미 발행된 " + nSkip + "건은 제외됩니다)";
        }

        MessageBox.confirm(sMsg, {
          title: "일괄 QR 발행",
          onClose: function (sAction) {
            if (sAction === MessageBox.Action.OK) {
              this._doIssueQr(aData);
            }
          }.bind(this),
        });
      },

      _doIssueQr: function (aDataList) {
        var oBusy = new BusyDialog({ text: "QR 발행 중..." });
        var oModel = this.getOwnerComponent().getModel();

        oModel.setUseBatch(false); // 배치 끄기 (즉시 전송)
        oModel.setRefreshAfterChange(false); // create 후 자동 refresh로 인한 대기 방지

        oBusy.open();

        console.log(
          "[QR] _doIssueQr 시작. model =",
          oModel,
          " / metadataLoaded?",
          oModel && oModel.getServiceMetadata
            ? !!oModel.getServiceMetadata()
            : "N/A",
        );

        // CSRF 토큰을 먼저 강제로 갱신 (토큰 fetch가 멈추면 create가 영원히 대기함)
        oModel.refreshSecurityToken(
          function () {
            console.log("[QR] CSRF 토큰 OK");
          },
          function (e) {
            console.error("[QR] CSRF 토큰 실패", e);
          },
        );

        // 무한버퍼링 방지: 15초 타임아웃
        var bDone = false;
        var oTimer = setTimeout(function () {
          if (!bDone) {
            oBusy.close();
            MessageBox.error(
              "응답 시간 초과(15초). 백엔드 응답이 없습니다.\n콘솔(F12)의 [QR] 로그를 확인하세요.",
            );
            console.warn(
              "[QR] 타임아웃 - create 콜백이 오지 않음 (요청 미전송 or 백엔드 무응답)",
            );
          }
        }, 15000);

        var aPromises = aDataList.map(function (oData) {
          return new Promise(function (resolve) {
            var oPayload = {
              Mblnr: oData.Mblnr,
              Mjahr: oData.Mjahr,
              Zeile: oData.Zeile,
              Matnr: oData.Matnr,
              Werks: oData.Werks || "TS00",
              Charg: oData.Charg || "",
              Ebeln: oData.Ebeln || "",
              Ebelp: oData.Ebelp || "",
              Lgort: oData.Lgort || "", // 입고 당시 저장위치
              Lifnr: oData.Lifnr || "", // 공급업체
              GrQty: oData.Menge, // 입고수량 스냅샷
              Meins: oData.Meins || "",
              GrDate: oData.Budat || null, // 입고일
              QrStatus: "I",
            };

            console.log("[QR] create 호출 payload =", oPayload);

            try {
              oModel.create("/QrHist", oPayload, {
                success: function (oResult) {
                  console.log("[QR] ✅ success", oResult);
                  resolve({ ok: true, data: oResult, src: oData });
                },
                error: function (oErr) {
                  console.error("[QR] ❌ error", oErr);
                  resolve({ ok: false, mblnr: oData.Mblnr, err: oErr });
                },
              });
              console.log("[QR] create 호출 완료(콜백 대기중)");
            } catch (ex) {
              console.error("[QR] ⚠️ create() 예외 발생", ex);
              resolve({ ok: false, mblnr: oData.Mblnr, ex: ex });
            }
          });
        });

        Promise.all(aPromises).then(
          function (aResults) {
            bDone = true;
            clearTimeout(oTimer);
            oBusy.close();

            var nOk = aResults.filter(function (r) {
              return r.ok;
            }).length;
            var nFail = aResults.length - nOk;

            if (nFail === 0) {
              MessageToast.show(nOk + "건 QR 발행 완료");
            } else {
              var sDetail = "";
              var oFirstErr = aResults.filter(function (r) {
                return !r.ok;
              })[0];
              if (oFirstErr && oFirstErr.err && oFirstErr.err.responseText) {
                sDetail = "\n\n" + oFirstErr.err.responseText.substring(0, 300);
              }
              MessageBox.warning(
                nOk + "건 성공 / " + nFail + "건 실패" + sDetail,
              );
            }
            this._loadList();
            this._hideDetail();

            // 발행 성공분 라벨 인쇄 제안
            var aLabels = aResults
              .filter(function (r) {
                return r.ok && r.data && r.data.QrNo;
              })
              .map(function (r) {
                return {
                  QrNo: r.data.QrNo,
                  Matnr: r.src.Matnr,
                  Maktx: r.src.Maktx,
                  Charg: r.src.Charg,
                  Menge: r.src.Menge,
                  Meins: r.src.Meins,
                  Mblnr: r.src.Mblnr,
                  Ebeln: r.src.Ebeln,
                };
              });

            if (aLabels.length > 0) {
              MessageBox.confirm(
                "발행된 QR 라벨 " + aLabels.length + "건을 인쇄하시겠습니까?",
                {
                  title: "라벨 인쇄",
                  onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) {
                      this._printLabels(aLabels);
                    }
                  }.bind(this),
                },
              );
            }
          }.bind(this),
        );
      },

      // ── 라벨 인쇄 (브라우저 인쇄 → PDF 저장 가능) ──────────

      _printLabels: function (aLabels) {
        var that = this;

        var fnEsc = function (s) {
          return String(s == null ? "" : s)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
        };

        var sLabelsHtml = aLabels
          .map(function (o) {
            var sQty =
              o.Menge != null
                ? that.fmtQty(o.Menge) + " " + (o.Meins || "")
                : "-";
            return (
              "<div class='label'>" +
              "<div class='qrbox' data-text='" +
              fnEsc(that._buildQrUrl(o.QrNo)) +
              "'></div>" +
              "<div class='qrno'>" +
              fnEsc(o.QrNo) +
              "</div>" +
              "<table class='info'>" +
              "<tr><td>자재</td><td>" +
              fnEsc(o.Matnr) +
              "</td></tr>" +
              "<tr><td>품명</td><td>" +
              fnEsc(o.Maktx) +
              "</td></tr>" +
              "<tr><td>배치</td><td>" +
              fnEsc(o.Charg) +
              "</td></tr>" +
              "<tr><td>수량</td><td>" +
              fnEsc(sQty) +
              "</td></tr>" +
              "<tr><td>입고문서</td><td>" +
              fnEsc(o.Mblnr) +
              "</td></tr>" +
              "<tr><td>PO</td><td>" +
              fnEsc(o.Ebeln) +
              "</td></tr>" +
              "</table>" +
              "</div>"
            );
          })
          .join("");

        var sHtml =
          "<!DOCTYPE html><html><head><meta charset='utf-8'>" +
          "<title>QR 라벨 인쇄</title>" +
          "<style>" +
          "body{font-family:'Malgun Gothic',sans-serif;margin:8mm;}" +
          ".sheet{display:flex;flex-wrap:wrap;gap:5mm;}" +
          ".label{width:58mm;border:1px solid #333;border-radius:2mm;" +
          "padding:3mm;box-sizing:border-box;text-align:center;" +
          "page-break-inside:avoid;}" +
          ".qrbox{display:flex;justify-content:center;}" +
          ".qrno{font-weight:bold;font-size:11pt;margin:1.5mm 0;}" +
          ".info{width:100%;font-size:7.5pt;border-collapse:collapse;text-align:left;}" +
          ".info td{padding:0.4mm 0;}" +
          ".info td:first-child{color:#666;width:16mm;}" +
          "@media print{body{margin:5mm;}}" +
          "</style></head><body>" +
          "<div class='sheet'>" +
          sLabelsHtml +
          "</div>" +
          "<scr" +
          "ipt src='https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js'></scr" +
          "ipt>" +
          "<scr" +
          "ipt>" +
          "window.onload=function(){" +
          "var els=document.querySelectorAll('.qrbox');" +
          "for(var i=0;i<els.length;i++){" +
          "new QRCode(els[i],{text:els[i].getAttribute('data-text')," +
          "width:110,height:110,correctLevel:QRCode.CorrectLevel.M});}" +
          "setTimeout(function(){window.print();},600);" +
          "};" +
          "</scr" +
          "ipt>" +
          "</body></html>";

        var oWin = window.open("", "_blank", "width=900,height=700");
        if (!oWin) {
          MessageBox.warning(
            "팝업이 차단되었습니다. 브라우저 팝업 허용 후 다시 시도하세요.",
          );
          return;
        }
        oWin.document.write(sHtml);
        oWin.document.close();
      },

      // ── QR 코드 렌더링 ─────────────────────────────────────

      _renderQrCode: function (sQrNo) {
        var iMySeq = ++this._iQrSeq; // 이 렌더의 순번
        var sQrText = this._buildQrUrl(sQrNo); // QR엔 URL을 인코딩

        // preferDOM=true HTML 컨트롤은 setContent로 DOM이 안 바뀌므로 직접 조작
        var oDom = document.getElementById("qrCodeDiv");
        if (oDom) {
          oDom.innerHTML = "";
          oDom.classList.remove("qrCodeEmpty");
        }

        setTimeout(
          function () {
            // 그 사이 다른 자재를 선택했으면(순번이 바뀜) 이 렌더는 폐기
            if (iMySeq !== this._iQrSeq) return;

            var oDom2 = document.getElementById("qrCodeDiv");
            if (!oDom2) return;
            oDom2.innerHTML = "";
            oDom2.classList.remove("qrCodeEmpty");

            var fnDraw = function () {
              if (iMySeq !== this._iQrSeq) return;
              oDom2.innerHTML = "";
              new QRCode(oDom2, {
                text: sQrText,
                width: 140,
                height: 140,
                colorDark: "#000000",
                colorLight: "#ffffff",
                correctLevel: QRCode.CorrectLevel.M,
              });
            }.bind(this);

            if (typeof QRCode !== "undefined") {
              fnDraw();
            } else {
              var oScript = document.createElement("script");
              oScript.src =
                "https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js";
              oScript.onload = fnDraw;
              document.head.appendChild(oScript);
            }
          }.bind(this),
          200,
        );
      },

      _clearQrCode: function () {
        ++this._iQrSeq; // 대기 중인 이전 렌더 전부 무효화

        // preferDOM=true라 setContent가 안 먹음 → DOM 직접 비우기
        var oDom = document.getElementById("qrCodeDiv");
        if (oDom) {
          oDom.classList.add("qrCodeEmpty");
          oDom.innerHTML = "<span>QR 미리보기</span>";
        }
      },

      // ── 재고조회 대시보드 (탭2) ─────────────────────────────

      // 자재 이미지: webapp/images/<자재번호>.png → 없으면 <자재명>.png → 없으면 아이콘
      _imgUrl: function (sName) {
        return (
          sap.ui.require.toUrl("c1/mm/c1mmqr/images") +
          "/" +
          encodeURIComponent(sName) +
          ".png"
        );
      },

      // 이미지 세팅 (1차: 자재번호, 실패 시 onDashImgError에서 자재명으로 재시도)
      // 자재번호 → 이미지 파일명 형식 (RMCTL100 → RM-CTL-100)
      _hyphenMatnr: function (s) {
        var m = /^([A-Z]{2})([A-Z]{3})(\d+)$/.exec((s || "").toUpperCase());
        return m ? m[1] + "-" + m[2] + "-" + m[3] : s;
      },

      // 실제 로드되는 URL만 골라 적용 (탭 렌더 타이밍과 무관하게 동작)
      _setMatImg: function (sMatnr, sMaktx) {
        var oImg = this.byId("dashMatImg");
        var oFb = this.byId("dashMatImgFallback");
        var aCands = [];
        if (sMatnr) {
          aCands.push(this._imgUrl(sMatnr));
          var sHy = this._hyphenMatnr(sMatnr);
          if (sHy !== sMatnr) {
            aCands.push(this._imgUrl(sHy));
          }
        }
        if (sMaktx) {
          aCands.push(this._imgUrl(sMaktx));
        }
        aCands.push(this._imgUrl("NO-IMAGE"));
        (function tryNext(i) {
          if (i >= aCands.length) {
            oImg.setVisible(false);
            oFb.setVisible(true);
            return;
          }
          var im = new window.Image();
          im.onload = function () {
            oImg.setSrc(aCands[i]);
            oImg.setVisible(true);
            oFb.setVisible(false);
          };
          im.onerror = function () {
            tryNext(i + 1);
          };
          im.src = aCands[i];
        })(0);
      },

      onDashScan: function () {
        CameraScanner.scan(
          function (sRaw) {
            var sText = (sRaw || "").trim();
            // QR에 URL이 들어있으면 QR번호만 추출
            var aMatch = sText.match(/#\/scan\/(.+)$/);
            if (aMatch) sText = decodeURIComponent(aMatch[1]);
            this.byId("inDashQuery").setValue(sText);
            this._dashLookup(sText);
          }.bind(this),
        );
      },

      onDashSearch: function () {
        var sQuery = this.byId("inDashQuery").getValue().trim();
        if (!sQuery) {
          MessageToast.show("자재번호를 입력하세요.");
          return;
        }
        this._dashLookup(sQuery);
      },

      onDashReset: function () {
        this.byId("inDashQuery").setValue("");
        this.byId("dashMatCard").setVisible(false);
        this.byId("dashWhBatchBox").setVisible(false); // 창고 클릭 배치 패널도 닫기
        this.byId("dashStockTable").destroyItems();
        this.byId("dkTotal").setText("-");
        this.byId("dkClabs").setText("-");
        this.byId("dkCinsm").setText("-");
        this.byId("dkCspem").setText("-");
        this.byId("dashChartHtml").setContent(
          "<div class='qrChartEmpty'>자재를 조회하면 차트가 표시됩니다</div>",
        );
        this.byId("dashMapHtml").setContent(
          "<div class='qrChartEmpty'>자재를 조회하면 위치가 표시됩니다</div>",
        );
        var oEta = this.byId("dashEtaBox");
        oEta.destroyItems();
        oEta.removeStyleClass("qrEtaFilled");
        oEta.addItem(
          new Text({ text: "자재를 조회하면 예측이 표시됩니다" }).addStyleClass(
            "qrChartEmpty",
          ),
        );
      },

      // 창고 현황 = 자재 단위 조회 (자재번호 입력). QR/배치는 'QR 스캔' 탭에서.
      // bNoHist=true 면 조회이력에 추가하지 않음 (이력 클릭 재조회용)
      _dashLookup: function (sQuery, bNoHist) {
        var sMatnr = (sQuery || "").trim().toUpperCase();
        if (!sMatnr) {
          return;
        }
        this._loadDashboard(sMatnr, null, bNoHist);
      },

      _loadDashboard: function (sMatnr, oExtra, bNoHist, bIsRetry) {
        var oModel = this.getOwnerComponent().getModel();
        var oTable = this.byId("dashStockTable");

        oTable.setBusy(true);

        oModel.read("/BatchStock", {
          filters: [new Filter("Matnr", FilterOperator.EQ, sMatnr)],
          success: function (oResult) {
            oTable.setBusy(false);
            var aRows = oResult.results || [];

            if (aRows.length === 0) {
              MessageToast.show("자재 [" + sMatnr + "] 의 재고가 없습니다.");
              // 조회 실패(없는 자재/오타)는 이력에 남기지 않음
              this._renderDashboard(sMatnr, [], oExtra, true);
              return;
            }
            this._renderDashboard(sMatnr, aRows, oExtra, bNoHist);

            // 자재명 보강 (QR조회가 아니어서 모를 때)
            if (!oExtra || !oExtra.maktx) {
              this._loadDashMatName(sMatnr);
            }
          }.bind(this),
          error: function (oErr) {
            // 일시적 네트워크/세션 끊김 대비: 1초 후 1회 자동 재시도
            if (!bIsRetry) {
              console.warn("[QR] 재고조회 실패 - 1회 재시도", oErr);
              setTimeout(
                function () {
                  this._loadDashboard(sMatnr, oExtra, bNoHist, true);
                }.bind(this),
                1000,
              );
              return;
            }
            oTable.setBusy(false);
            MessageToast.show(
              "재고 조회 실패 - 네트워크 상태를 확인 후 다시 시도해 주세요.",
            );
            console.error("[QR] 재고조회 재시도도 실패", oErr);
          }.bind(this),
        });
      },

      _loadDashMatName: function (sMatnr) {
        var oModel = this.getOwnerComponent().getModel();
        oModel.read("/QrTarget", {
          filters: [new Filter("Matnr", FilterOperator.EQ, sMatnr)],
          urlParameters: { $top: "1" },
          success: function (oResult) {
            var aRows = oResult.results || [];
            if (aRows.length > 0) {
              this.byId("dashMatTitle").setText(aRows[0].Maktx || sMatnr);
              this.byId("dashMeins").setText(aRows[0].Meins || "");

              // 자재명을 늦게 알게 된 경우: 이미지가 아이콘으로 빠져있으면 자재명으로 재시도
              if (
                aRows[0].Maktx &&
                this.byId("dashMatImgFallback").getVisible()
              ) {
                this._sImgMaktx = aRows[0].Maktx;
                this._iImgTry = 2;
                this.byId("dashMatImgFallback").setVisible(false);
                var oImg = this.byId("dashMatImg");
                oImg.setVisible(true);
                oImg.setSrc(this._imgUrl(aRows[0].Maktx));
              }
            }
          }.bind(this),
        });
      },

      _renderDashboard: function (sMatnr, aRows, oExtra, bNoHist) {
        var oTable = this.byId("dashStockTable");
        oTable.destroyItems();
        this._aLastStock = aRows || []; // 3D 맵 창고 클릭 시 배치 목록용
        this._sLastMeins = (aRows && aRows[0] && aRows[0].Meins) || "";
        this.byId("dashWhBatchBox").setVisible(false); // 새 조회 시 배치 패널 닫기

        // 창고(Lgort)별 집계
        var mLgort = {};
        var nTotClabs = 0,
          nTotCinsm = 0,
          nTotCspem = 0,
          nTotUmlme = 0;

        aRows.forEach(function (oRow) {
          var sLgort = oRow.Lgort;
          if (!mLgort[sLgort]) {
            mLgort[sLgort] = {
              clabs: 0,
              cinsm: 0,
              cspem: 0,
              umlme: 0,
              meins: oRow.Meins,
            };
          }
          mLgort[sLgort].clabs += parseFloat(oRow.Clabs || 0);
          mLgort[sLgort].cinsm += parseFloat(oRow.Cinsm || 0);
          mLgort[sLgort].cspem += parseFloat(oRow.Cspem || 0);
          mLgort[sLgort].umlme += parseFloat(oRow.Umlme || 0);

          nTotClabs += parseFloat(oRow.Clabs || 0);
          nTotCinsm += parseFloat(oRow.Cinsm || 0);
          nTotCspem += parseFloat(oRow.Cspem || 0);
          nTotUmlme += parseFloat(oRow.Umlme || 0);
        });

        var nTotal = nTotClabs + nTotCinsm + nTotCspem + nTotUmlme;

        // KPI
        this.byId("dkTotal").setText(this._fmtQty(nTotal));
        this.byId("dkClabs").setText(this._fmtQty(nTotClabs));
        this.byId("dkCinsm").setText(this._fmtQty(nTotCinsm));
        this.byId("dkCspem").setText(this._fmtQty(nTotCspem));

        // 창고별 행
        Object.keys(mLgort)
          .sort()
          .forEach(function (sLgort) {
            var o = mLgort[sLgort];
            var nRowTotal = o.clabs + o.cinsm + o.cspem + o.umlme;
            var sState =
              o.clabs > 0 ? "Success" : o.cinsm > 0 ? "Warning" : "Error";
            var sStateText =
              o.clabs > 0 ? "가용" : o.cinsm > 0 ? "검사중" : "보류";

            oTable.addItem(
              new ColumnListItem({
                cells: [
                  new Text({ text: this._lgortName(sLgort) }),
                  new ObjectNumber({
                    number: this._fmtQty(o.clabs),
                    state: o.clabs > 0 ? "Success" : "None",
                  }),
                  new ObjectNumber({
                    number: this._fmtQty(o.cinsm),
                    state: o.cinsm > 0 ? "Warning" : "None",
                  }),
                  new ObjectNumber({
                    number: this._fmtQty(o.cspem),
                    state: o.cspem > 0 ? "Error" : "None",
                  }),
                  new ObjectNumber({
                    number: this._fmtQty(nRowTotal),
                    emphasized: true,
                  }),
                  new ObjectNumber({ number: sStateText, state: sState }),
                ],
              }),
            );
          }, this);

        // 자재 정보 카드 (창고 현황 = 자재 단위, 배치 정보는 스캔 탭)
        this.byId("dashMatCard").setVisible(true);
        this.byId("dashMatnr").setText(sMatnr);
        this.byId("dashMatTitle").setText((oExtra && oExtra.maktx) || sMatnr);
        this.byId("dashMeins").setText(
          (oExtra && oExtra.meins) || (aRows[0] && aRows[0].Meins) || "",
        );

        // 자재 이미지 (자재번호.png → 자재명.png → 아이콘)
        this._setMatImg(
          sMatnr,
          (oExtra && oExtra.maktx) || this.byId("dashMatTitle").getText() || "",
        );

        // 차트 / 배치도 / 입고예정
        this._mLastLgort = mLgort; // PO입고예정 도착 시 차트 갱신용
        this._renderDashChart(mLgort);
        this._renderDashMap(mLgort);
        this._renderDashEta(nTotClabs, nTotCinsm, sMatnr);

        // 조회 이력 (이력 클릭 재조회 시에는 추가 안 함)
        if (!bNoHist) {
          var oList = this.byId("dashHistList");

          // 직전 조회와 같은 자재면 중복 추가 대신 기존 항목 제거 후 갱신
          var aExist = oList.getItems();
          if (aExist.length > 0 && aExist[0].getTitle() === sMatnr) {
            oList.removeItem(aExist[0]);
          }

          oList.insertItem(
            new sap.m.StandardListItem({
              title: sMatnr,
              description:
                new Date().toLocaleTimeString("ko-KR") +
                " · 가용 " +
                this._fmtQty(nTotClabs),
              icon: "sap-icon://bar-code",
              type: "Active",
              press: function () {
                this.byId("inDashQuery").setValue(sMatnr);
                this._dashLookup(sMatnr, true); // bNoHist=true
              }.bind(this),
            }),
            0,
          );
          var aItems = oList.getItems();
          if (aItems.length > 15) oList.removeItem(aItems[aItems.length - 1]);
        }
      },

      // ── 재고 분포 차트 (창고별 가로 스택바 + 입고예정) ───────
      _renderDashChart: function (mLgort, nIncoming) {
        nIncoming = nIncoming || 0;

        var aKeys = Object.keys(mLgort).sort();
        // 입고예정은 SL40(품질검사창고)으로 들어오므로 SL40 막대에 합산 표시
        if (nIncoming > 0 && aKeys.indexOf("SL40") < 0) {
          aKeys.push("SL40");
          aKeys.sort();
        }

        var nMax = 0;
        aKeys.forEach(function (k) {
          var o = mLgort[k] || { clabs: 0, cinsm: 0, cspem: 0, umlme: 0 };
          var nTot = o.clabs + o.cinsm + o.cspem + o.umlme;
          if (k === "SL40") nTot += nIncoming;
          nMax = Math.max(nMax, nTot);
        });
        if (nMax === 0) nMax = 1;

        var that = this;
        var sHtml = "<div class='qrChart'>";
        aKeys.forEach(function (k) {
          var o = mLgort[k] || { clabs: 0, cinsm: 0, cspem: 0, umlme: 0 };
          var nTot = o.clabs + o.cinsm + o.cspem + o.umlme;
          var nIn = k === "SL40" ? nIncoming : 0;
          var nBar = nTot + nIn;
          if (nBar <= 0) return;

          var wAll = (nBar / nMax) * 100;
          var pC = (o.clabs / nBar) * 100;
          var pI = (o.cinsm / nBar) * 100;
          var pS = (o.cspem / nBar) * 100;
          var pIn = (nIn / nBar) * 100;

          var sVal = that._fmtQty(nTot);
          if (nIn > 0) {
            sVal +=
              " <span class='qrChartValIn'>+" + that._fmtQty(nIn) + "</span>";
          }

          sHtml +=
            "<div class='qrChartRow'>" +
            "<span class='qrChartLabel'>" +
            that._lgortName(k) +
            "</span>" +
            "<span class='qrChartBarWrap'>" +
            "<span class='qrChartBar' style='width:" +
            wAll +
            "%'>" +
            "<span class='qrChartSeg qrChartSeg--ok' style='width:" +
            pC +
            "%'></span>" +
            "<span class='qrChartSeg qrChartSeg--qi' style='width:" +
            pI +
            "%'></span>" +
            "<span class='qrChartSeg qrChartSeg--bl' style='width:" +
            pS +
            "%'></span>" +
            "<span class='qrChartSeg qrChartSeg--in' style='width:" +
            pIn +
            "%'></span>" +
            "</span></span>" +
            "<span class='qrChartVal'>" +
            sVal +
            "</span>" +
            "</div>";
        });

        sHtml +=
          "<div class='qrChartLegend'>" +
          "<span><i class='qrChartSeg--ok'></i>가용</span>" +
          "<span><i class='qrChartSeg--qi'></i>검사중</span>" +
          "<span><i class='qrChartSeg--bl'></i>보류</span>" +
          (nIncoming > 0
            ? "<span><i class='qrChartSeg--in'></i>입고예정</span>"
            : "") +
          "</div></div>";

        this.byId("dashChartHtml").setContent(sHtml);
      },

      // 저장위치 코드 → 창고명
      _lgortName: function (sLgort) {
        var m = {
          SL10: "원자재",
          SL20: "반제품",
          SL30: "완제품",
          SL40: "품질검사",
          SL50: "보류/반품",
        };
        return m[sLgort] || sLgort || "";
      },

      // ── 창고 배치도 (3D 아이소메트릭 · 오픈 랙) ──────────────
      _renderDashMap: function (mLgort) {
        var that = this;
        // 코스트코식 긴 통로 랙 — 창고(저장위치)별 1열
        var rows = [
          { id: "SL40", name: "품질검사", y: 0.0 },
          { id: "SL10", name: "원자재", y: 3.2 },
          { id: "SL20", name: "반제품", y: 6.4 },
          { id: "SL50", name: "보류/반품", y: 9.6 },
          { id: "SL30", name: "완제품", y: 12.8, bikes: true },
        ];
        var nMax = 0;
        rows.forEach(function (r) {
          var o = mLgort[r.id];
          if (o) {
            nMax = Math.max(nMax, o.clabs + o.cinsm + o.cspem + o.umlme);
          }
        });

        // 아이소 투영 (x=랙 길이, y=통로 깊이, z=높이[px])
        var ox = 384,
          oy = 100,
          ux = 22,
          uy = 10.5;
        function iso(x, y, z) {
          return [ox + (x - y) * ux, oy + (x + y) * uy - z];
        }
        function P(a) {
          return a[0].toFixed(1) + "," + a[1].toFixed(1);
        }
        function poly(pts, fill, op, stroke, sw) {
          return (
            "<polygon points='" +
            pts.map(P).join(" ") +
            "' fill='" +
            fill +
            "'" +
            (op != null ? " fill-opacity='" + op + "'" : "") +
            (stroke
              ? " stroke='" + stroke + "' stroke-width='" + sw + "'"
              : "") +
            "/>"
          );
        }
        function line(a, b, c, w) {
          return (
            "<line x1='" +
            a[0].toFixed(1) +
            "' y1='" +
            a[1].toFixed(1) +
            "' x2='" +
            b[0].toFixed(1) +
            "' y2='" +
            b[1].toFixed(1) +
            "' stroke='" +
            c +
            "' stroke-width='" +
            w +
            "'/>"
          );
        }
        function pbox(x, y, z, dx, dy, dz, t, l, r) {
          var x1 = x + dx,
            y1 = y + dy,
            z1 = z + dz,
            ed = "#46535f";
          // 보이는 3면: 정면(y=y1) · 우측(x=x1) · 윗면
          var Fr = [
            iso(x, y1, z),
            iso(x1, y1, z),
            iso(x1, y1, z1),
            iso(x, y1, z1),
          ];
          var Ri = [
            iso(x1, y, z),
            iso(x1, y1, z),
            iso(x1, y1, z1),
            iso(x1, y, z1),
          ];
          var Tp = [
            iso(x, y, z1),
            iso(x1, y, z1),
            iso(x1, y1, z1),
            iso(x, y1, z1),
          ];
          return (
            poly(Fr, l, null, ed, 0.6) +
            poly(Ri, r, null, ed, 0.6) +
            poly(Tp, t, null, ed, 0.6)
          );
        }
        function bikeStand(px, py, c) {
          function wheel(wx) {
            return (
              "<circle cx='" +
              wx +
              "' cy='0' r='30' fill='none' stroke='#222831' stroke-width='6'/>" +
              "<circle cx='" +
              wx +
              "' cy='0' r='23' fill='none' stroke='#c7ccd2' stroke-width='2.5'/>" +
              "<g stroke='#b3bbc4' stroke-width='1'><line x1='" +
              wx +
              "' y1='-22' x2='" +
              wx +
              "' y2='22'/><line x1='" +
              (wx - 22) +
              "' y1='0' x2='" +
              (wx + 22) +
              "' y2='0'/><line x1='" +
              (wx - 16) +
              "' y1='-16' x2='" +
              (wx + 16) +
              "' y2='16'/><line x1='" +
              (wx - 16) +
              "' y1='16' x2='" +
              (wx + 16) +
              "' y2='-16'/></g>" +
              "<circle cx='" +
              wx +
              "' cy='0' r='3.5' fill='#52606e'/>"
            );
          }
          var frame =
            "<path d='M-46,0 L0,2 L46,0'/><path d='M0,2 L-14,-34 L30,-32'/><path d='M-14,-34 L-46,0'/><path d='M30,-32 L46,0'/>";
          return (
            "<g transform='translate(" +
            px.toFixed(1) +
            "," +
            py.toFixed(1) +
            ") scale(0.3)'>" +
            "<ellipse cx='0' cy='34' rx='70' ry='10' fill='#1b2a3d' opacity='0.10'/>" +
            wheel(-46) +
            wheel(46) +
            "<g fill='none' stroke-linecap='round' stroke-linejoin='round'><g stroke='#3a4654' stroke-width='8'>" +
            frame +
            "</g><g stroke='" +
            c +
            "' stroke-width='5'>" +
            frame +
            "</g></g>" +
            "<path d='M-20,-36 L-6,-35' stroke='#2a3540' stroke-width='5' fill='none' stroke-linecap='round'/>" +
            "<path d='M30,-32 L42,-40' stroke='#2a3540' stroke-width='4.5' fill='none' stroke-linecap='round'/>" +
            "<circle cx='0' cy='2' r='6' fill='none' stroke='#16364a' stroke-width='3'/></g>"
          );
        }

        var L = 12,
          dep = 1.0,
          H = 80,
          nLv = 5,
          lvlGap = H / nLv,
          bayStep = 2;
        var nBay = Math.round(L / bayStep);
        var UNITS_PER_BOX = 2000; // 박스 1칸 = 2,000 EA 기준 (조정 가능)

        var svg =
          "<svg viewBox='0 0 820 460' width='100%' style='display:block;max-height:460px' xmlns='http://www.w3.org/2000/svg'>";
        svg +=
          "<defs><radialGradient id='qmSky' cx='50%' cy='30%' r='62%'><stop offset='0' stop-color='#fffdf4' stop-opacity='0.7'/><stop offset='1' stop-color='#fffdf4' stop-opacity='0'/></radialGradient>" +
          "<linearGradient id='qmFloor' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#eff3f8'/><stop offset='1' stop-color='#dde4ed'/></linearGradient></defs>";
        svg +=
          "<rect x='0' y='0' width='820' height='460' fill='url(#qmSky)'/>";
        // 바닥
        svg += poly(
          [
            iso(-1, -1, 0),
            iso(L + 1.5, -1, 0),
            iso(L + 1.5, 14.5, 0),
            iso(-1, 14.5, 0),
          ],
          "url(#qmFloor)",
          null,
          "#cdd6e0",
          1,
        );
        // 통로 라인(은은한 점선)
        rows.forEach(function (r) {
          var a = iso(0, r.y + dep + 0.7, 0.1),
            b = iso(L, r.y + dep + 0.7, 0.1);
          svg +=
            "<line x1='" +
            a[0].toFixed(1) +
            "' y1='" +
            a[1].toFixed(1) +
            "' x2='" +
            b[0].toFixed(1) +
            "' y2='" +
            b[1].toFixed(1) +
            "' stroke='#cbd4df' stroke-width='1.4' stroke-dasharray='4 5'/>";
        });

        // 뒤(작은 y) → 앞 순서로
        rows
          .slice()
          .sort(function (a, b) {
            return a.y - b.y;
          })
          .forEach(function (r) {
            var o = mLgort[r.id];
            var tot = o ? o.clabs + o.cinsm + o.cspem + o.umlme : 0;
            var active = tot > 0;
            var y = r.y,
              steel = "#9aa6b4";
            var f0 = iso(0, y, 0),
              f1 = iso(L, y, 0),
              f2 = iso(L, y + dep, 0),
              f3 = iso(0, y + dep, 0);

            if (r.bikes) {
              // 완제품 = 자전거 staging (선반 없이 바닥)
              svg += poly(
                [f0, f1, f2, f3],
                active ? "#e7f6ec" : "#eef1f5",
                0.85,
                active ? "#7fbf8c" : "#d6dde6",
                1,
              );
              if (active) {
                var pal = [
                  "#1f2937",
                  "#ffffff",
                  "#c0392b",
                  "#2c3e50",
                  "#e67e22",
                ];
                var nb = Math.max(
                  2,
                  Math.min(5, Math.ceil(tot / UNITS_PER_BOX)),
                );
                for (var i = 0; i < nb; i++) {
                  var bp = iso(1.5 + i * 2.4, y + 0.5, 0);
                  svg += bikeStand(bp[0], bp[1], pal[i % pal.length]);
                }
              }
            } else if (!active) {
              // 재고 없는 창고 = 선반 제거, 빈 공간만
              svg += poly([f0, f1, f2, f3], "#eef1f5", 0.6, "#d6dde6", 1);
            } else {
              var tint = r.id === "SL50" ? "#f3e1e4" : "#e3ebf3";
              var edge = r.id === "SL50" ? "#d79a9a" : "#9fb6d4";
              svg += poly([f0, f1, f2, f3], tint, 0.3, edge, 1);
              // 기둥(앞/뒤)
              for (var bx = 0; bx <= nBay; bx++) {
                var px = bx * bayStep;
                svg += line(iso(px, y, 0), iso(px, y, H), steel, 1.8);
                svg += line(
                  iso(px, y + dep, 0),
                  iso(px, y + dep, H),
                  steel,
                  1.8,
                );
              }
              // 선반 데크(층) — 면 없이 뼈대(선)만, 박스를 가리지 않게
              for (var v = 1; v <= nLv; v++) {
                var z = lvlGap * v;
                svg += poly(
                  [
                    iso(0, y, z),
                    iso(L, y, z),
                    iso(L, y + dep, z),
                    iso(0, y + dep, z),
                  ],
                  "none",
                  null,
                  steel,
                  1,
                );
              }
              // 팔레트 적재(재고량 비례 단수) — 또렷한 큐브
              var t, l, rr;
              if (o.clabs > 0) {
                t = "#92d29d";
                l = "#5fae6e";
                rr = "#4d9a5d";
              } else if (o.cinsm > 0) {
                t = "#f7c07c";
                l = "#dd9a45";
                rr = "#cd8a36";
              } else {
                t = "#e6a0a0";
                l = "#cf8080";
                rr = "#bd6e6e";
              }
              // 박스 1칸 = UNITS_PER_BOX EA, 아래층부터 좌→우로 채움
              var nBoxes = Math.min(
                nBay * nLv,
                Math.max(1, Math.ceil(tot / UNITS_PER_BOX)),
              );
              var placed = 0;
              for (var k = 0; k < nLv && placed < nBoxes; k++) {
                for (var b = 0; b < nBay && placed < nBoxes; b++) {
                  svg += pbox(
                    b * bayStep + 0.06,
                    y + 0.06,
                    k * lvlGap + 0.4,
                    bayStep - 0.12,
                    dep - 0.12,
                    lvlGap - 0.8,
                    t,
                    l,
                    rr,
                  );
                  placed++;
                }
              }
            }

            // 행거 사인 — 재고 있는 창고만 (빈 창고는 이름표 숨김)
            if (active) {
              var hasRack = !r.bikes;
              var signZ = hasRack ? H + 14 : 24;
              var top = iso(L / 2, y + dep / 2, signZ);
              svg += line(
                iso(L / 2, y + dep / 2, signZ),
                iso(L / 2, y + dep / 2, hasRack ? H : 0),
                "#c2ccd8",
                1.2,
              );
              svg +=
                "<rect x='" +
                (top[0] - 46).toFixed(1) +
                "' y='" +
                (top[1] - 13).toFixed(1) +
                "' width='92' height='19' rx='9' fill='" +
                (r.bikes ? "#15803d" : "#102a43") +
                "'/>";
              svg +=
                "<text x='" +
                top[0].toFixed(1) +
                "' y='" +
                (top[1] + 0.5).toFixed(1) +
                "' font-size='10' font-weight='700' fill='#fff' text-anchor='middle'>" +
                (r.bikes ? "완제품·완성차" : r.name) +
                "</text>";
            }
            var qp = iso(L + 0.4, y + dep / 2, 4);
            svg +=
              "<text x='" +
              qp[0].toFixed(1) +
              "' y='" +
              qp[1].toFixed(1) +
              "' font-size='11' font-weight='800' fill='" +
              (active ? (r.id === "SL50" ? "#bb0000" : "#1d2d3e") : "#aab4c0") +
              "'>" +
              (active ? that._fmtQty(tot) : "비어있음") +
              "</text>";

            // 클릭 영역 — 랙 전체(앞면+윗면) 덮어서 어디 눌러도 됨 (호버 시 하이라이트)
            if (active && !r.bikes) {
              var ff = [
                iso(0, y + dep, 0),
                iso(L, y + dep, 0),
                iso(L, y + dep, H),
                iso(0, y + dep, H),
              ];
              var tf = [
                iso(0, y, H),
                iso(L, y, H),
                iso(L, y + dep, H),
                iso(0, y + dep, H),
              ];
              svg +=
                "<polygon class='qrIsoTop' data-lgort='" +
                r.id +
                "' points='" +
                ff.map(P).join(" ") +
                "' fill='#0a6ed1' fill-opacity='0' style='cursor:pointer'/>";
              svg +=
                "<polygon class='qrIsoTop' data-lgort='" +
                r.id +
                "' points='" +
                tf.map(P).join(" ") +
                "' fill='#0a6ed1' fill-opacity='0' style='cursor:pointer'/>";
            } else {
              svg +=
                "<polygon class='qrIsoTop' data-lgort='" +
                r.id +
                "' points='" +
                [f0, f1, f2, f3].map(P).join(" ") +
                "' fill='#0a6ed1' fill-opacity='0'" +
                (active ? " style='cursor:pointer'" : "") +
                "/>";
            }
          });

        // 브랜드 엠블럼
        svg +=
          "<g stroke='#aab9cd' stroke-width='2' fill='none' opacity='0.4' transform='translate(728,432) scale(0.55)'>" +
          "<circle cx='0' cy='0' r='14'/><circle cx='48' cy='0' r='14'/>" +
          "<path d='M0,0 L18,-24 L38,0 M18,-24 L10,0 M38,0 L32,-24 L14,-24'/></g>";

        svg += "</svg>";
        this.byId("dashMapHtml").setContent(svg);
        this._bindMapClicks();
      },

      // 3D 맵 창고(top) 클릭 → 그 창고의 배치 목록 표시
      _bindMapClicks: function () {
        var that = this;
        setTimeout(function () {
          var oDom = that.byId("dashMapHtml").getDomRef();
          if (!oDom) {
            return;
          }
          var aTops = oDom.querySelectorAll(".qrIsoTop");
          Array.prototype.forEach.call(aTops, function (el) {
            el.onclick = function () {
              that._onWhClick(el.getAttribute("data-lgort"));
            };
          });
        }, 0);
      },

      _onWhClick: function (sLgort) {
        var aRows = (this._aLastStock || []).filter(function (r) {
          var n =
            parseFloat(r.Clabs || 0) +
            parseFloat(r.Cinsm || 0) +
            parseFloat(r.Cspem || 0) +
            parseFloat(r.Umlme || 0);
          return (r.Lgort || "") === sLgort && n !== 0;
        });
        var oBox = this.byId("dashWhBatchBox");
        var oList = this.byId("dashWhBatchList");
        oList.destroyItems();
        this.byId("dashWhBatchTitle").setText(
          this._lgortName(sLgort) + "창고 · 배치 " + aRows.length,
        );

        aRows.forEach(function (r) {
          var c = parseFloat(r.Clabs || 0),
            i = parseFloat(r.Cinsm || 0),
            s = parseFloat(r.Cspem || 0),
            u = parseFloat(r.Umlme || 0);
          var n = c + i + s + u;
          var sSt =
            c > 0 ? "가용" : i > 0 ? "검사중" : s > 0 ? "보류" : "이동중";
          oList.addItem(
            new sap.m.StandardListItem({
              title: r.Charg || "(배치없음)",
              info: this._fmtQty(n) + " " + (r.Meins || ""),
              description: sSt,
              type: "Active",
            }),
          );
        }, this);

        oBox.setVisible(true);
      },

      onWhBatchClose: function () {
        this.byId("dashWhBatchBox").setVisible(false);
      },

      // ── 입고 예정 ───────────────────────────────────────────
      // 1) 품질검사중 → 가용 전환 (품질 리드타임 3일)
      // 2) 미입고 PO → 정보레코드 리드타임 기준 입고 예측 (백엔드 /PoEta 필요)
      QI_LEADTIME_DAYS: 3,
      _iEtaSeq: 0, // 렌더 순번 (늦게 도착한 이전 PO 응답 무시용)

      _renderDashEta: function (nClabs, nCinsm, sMatnr) {
        var iMySeq = ++this._iEtaSeq;
        var oBox = this.byId("dashEtaBox");
        oBox.destroyItems();
        oBox.addStyleClass("qrEtaFilled"); // 실제 내용 → 위 정렬

        var nExpected = nClabs;

        // [1] 품질검사 전환 예측 — SL40 최신 입고일 + 품질검사일 기준
        if (nCinsm > 0) {
          var oQi = new sap.m.ObjectStatus({
            state: "Warning",
            icon: "sap-icon://lab",
          });
          oBox.addItem(oQi);
          var oQiSub = new Text({ text: "" }).addStyleClass("qrDashHint qrEtaSub");
          oBox.addItem(oQiSub);
          nExpected += nCinsm;
          this._renderQiEta(oQi, oQiSub, nCinsm, sMatnr, iMySeq);
        } else {
          oBox.addItem(
            new Text({
              text: "품질검사중 재고 없음",
            }).addStyleClass("qrDashHint"),
          );
        }

        // [2] 미입고 PO 예측 (백엔드 PoEta CDS 연동 — 없으면 자동 스킵)
        var oModel = this.getOwnerComponent().getModel();
        oModel.read("/PoEta", {
          filters: [new Filter("Matnr", FilterOperator.EQ, sMatnr)],
          success: function (oResult) {
            if (iMySeq !== this._iEtaSeq) return; // 이미 새 조회가 그렸으면 폐기
            var aRows = oResult.results || [];
            var nPoSum = 0;
            var nPoCnt = 0;
            var sMeins = "";

            aRows.forEach(function (oRow) {
              var nQty = parseFloat(oRow.OpenQty || 0);
              if (nQty <= 0) return;
              // 구매오더(3xxx)만 — 6xxx 등 다른 문서 제외
              if (!/^3/.test(oRow.Ebeln || "")) return;
              nPoSum += nQty;
              nPoCnt += 1;
              sMeins = oRow.Meins || sMeins;

              // 1줄: PO+수량 / 2줄: 입고예상일 (줄바꿈 없이 가독성 확보)
              oBox.addItem(
                new sap.m.ObjectStatus({
                  text:
                    "구매오더 " +
                    oRow.Ebeln +
                    " : +" +
                    this._fmtQty(nQty) +
                    " " +
                    (oRow.Meins || ""),
                  state: "Information",
                  icon: "sap-icon://shipping-status",
                }).addStyleClass("sapUiTinyMarginTop qrEtaLine1"),
              );
              oBox.addItem(
                new Text({
                  text:
                    "입고예상 " +
                    this.fmtDate(oRow.EtaDate) +
                    " (소요 " +
                    (oRow.LeadDays || 0) +
                    "일)",
                }).addStyleClass("qrEtaLine2"),
              );
            }, this);

            // PO 요약문구
            if (nPoCnt > 0) {
              oBox.addItem(
                new Text({
                  text:
                    "※ 승인 구매오더 " +
                    nPoCnt +
                    "건 · 합계 +" +
                    this._fmtQty(nPoSum) +
                    " " +
                    sMeins +
                    " 입고 예정",
                }).addStyleClass("qrDashHint sapUiTinyMarginTop"),
              );

              // 차트에 입고예정(파란색) 반영
              if (this._mLastLgort) {
                this._renderDashChart(this._mLastLgort, nPoSum);
              }
            }

            this._renderEtaSummary(oBox, nClabs, nExpected + nPoSum);
          }.bind(this),
          error: function () {
            if (iMySeq !== this._iEtaSeq) return; // 이미 새 조회가 그렸으면 폐기
            // PoEta CDS 미구현 시: 품질전환 예측만으로 요약
            this._renderEtaSummary(oBox, nClabs, nExpected);
          }.bind(this),
        });
      },

      // 검사중 → 가용 전환 예정일: SL40 최신 입고일 + 품질검사일
      _renderQiEta: function (oQi, oQiSub, nCinsm, sMatnr, iMySeq) {
        var that = this;
        var apply = function (dBase) {
          if (iMySeq !== that._iEtaSeq) return; // 이미 새 조회가 그렸으면 폐기
          var dEta = new Date(dBase || new Date());
          dEta.setDate(dEta.getDate() + that.QI_LEADTIME_DAYS);
          var dToday = new Date();
          dToday.setHours(0, 0, 0, 0);

          if (dBase && dEta < dToday) {
            // 전환 예정일이 지났는데 아직 검사중 → 검사 지연
            oQi.setText("검사중 " + that._fmtQty(nCinsm) + " EA · 가용 전환 지연");
            oQi.setState("Error");
            oQiSub.setText("검사 완료 예정일 " + that.fmtDate(dEta) + " 경과");
          } else {
            oQi.setText("검사중 " + that._fmtQty(nCinsm) + " EA · 가용 전환 예정");
            oQi.setState("Warning");
            oQiSub.setText(
              that.fmtDate(dEta) + " 전환 예정 · 품질검사 " + that.QI_LEADTIME_DAYS + "일 소요",
            );
          }
        };

        // 우선 오늘 기준으로 즉시 표시 → SL40 입고일 조회되면 갱신
        apply(null);

        var oModel = this.getOwnerComponent().getModel();
        oModel.read("/BatchHist", {
          filters: [
            new Filter("Matnr", FilterOperator.EQ, sMatnr),
            new Filter("Lgort", FilterOperator.EQ, "SL40"),
            new Filter({
              filters: [
                new Filter("Bwart", FilterOperator.EQ, "101"),
                new Filter("Bwart", FilterOperator.EQ, "131"),
              ],
              and: false,
            }),
          ],
          sorters: [new Sorter("Budat", true)], // 최신 입고일
          urlParameters: { $top: "1" },
          success: function (oRes) {
            var a = (oRes && oRes.results) || [];
            if (a.length && a[0].Budat) {
              apply(a[0].Budat);
            }
          },
          error: function () {
            /* BatchHist 미연동 시 오늘 기준 유지 */
          },
        });
      },

      _renderEtaSummary: function (oBox, nNow, nExpected) {
        if (nExpected <= nNow) return;

        var sPct =
          nNow > 0
            ? "+" + Math.round(((nExpected - nNow) / nNow) * 100) + "%"
            : "신규";

        oBox.addItem(
          new sap.m.ObjectStatus({
            text: "가용재고 " + sPct + " 증가 예상",
            state: "Success",
            icon: "sap-icon://trend-up",
          }).addStyleClass("sapUiTinyMarginTop"),
        );
        oBox.addItem(
          new Text({
            text:
              "현재 " +
              this._fmtQty(nNow) +
              " → 예상 " +
              this._fmtQty(nExpected) +
              " EA",
          }).addStyleClass("qrDashHint qrEtaSub"),
        );
        oBox.addItem(
          new Text({
            text:
              "※ 품질검사 " +
              this.QI_LEADTIME_DAYS +
              "일 소요(품질검사창고→원자재창고) + 구매오더별 입고 소요일 기준",
          }).addStyleClass("qrDashHint sapUiTinyMarginTop"),
        );
      },

      // 이미지 로드 실패: 자재번호 → 자재명 → '이미지 없음.png' → 아이콘
      onDashImgError: function () {
        var oImg = this.byId("dashMatImg");
        var that = this;
        // 0) 첫 실패: 탭 렌더 직후 타이밍 문제일 수 있으니 원본 자재이미지 1회 재시도
        if (this._iImgTry === 0) {
          this._iImgTry = 1;
          setTimeout(function () {
            oImg.setSrc(that._imgUrl(that._sImgMatnr));
          }, 200);
          return;
        }
        // 1) 자재명 이미지
        if (this._iImgTry === 1 && this._sImgMaktx) {
          this._iImgTry = 2;
          oImg.setSrc(this._imgUrl(this._sImgMaktx));
          return;
        }
        // 2) 이미지 없음 placeholder
        if (this._iImgTry <= 2) {
          this._iImgTry = 3;
          oImg.setSrc(this._imgUrl("NO-IMAGE"));
          return;
        }
        oImg.setVisible(false);
        this.byId("dashMatImgFallback").setVisible(true);
      },

      _fmtQty: function (n) {
        return Number(n || 0).toLocaleString("ko-KR", {
          maximumFractionDigits: 3,
        });
      },

      // ── 정렬 ───────────────────────────────────────────────

      onSortPress: function (oEvent) {
        var oButton = oEvent.getSource();
        var that = this;
        var oSheet = new ActionSheet({
          title: "정렬 기준",
          buttons: [
            new Button({
              text: "입고일 ↓ (최신)",
              press: function () {
                that._applySort("Bldat", true);
              },
            }),
            new Button({
              text: "입고일 ↑ (오래된)",
              press: function () {
                that._applySort("Bldat", false);
              },
            }),
            new Button({
              text: "자재번호 ↑",
              press: function () {
                that._applySort("Matnr", false);
              },
            }),
            new Button({
              text: "구매오더번호 ↑",
              press: function () {
                that._applySort("Ebeln", false);
              },
            }),
          ],
        });
        oSheet.openBy(oButton);
      },

      _applySort: function (sField, bDesc) {
        this._sSortField = sField;
        this._bSortDesc = bDesc;
        this._loadList();
      },

      // ── 네비게이션 ─────────────────────────────────────────

      onNavToScan: function () {
        // 별도 스캔화면 대신 재고조회 탭으로 통일
        this.byId("mainTabs").setSelectedKey("lookup");
      },

      onNavToHist: function () {
        this.getOwnerComponent().getRouter().navTo("RouteqrHist");
      },

      // ── 포맷터 ─────────────────────────────────────────────

      fmtDate: function (oDate) {
        if (!oDate) return "-";
        var d = oDate instanceof Date ? oDate : new Date(oDate);
        if (isNaN(d.getTime())) return "-";
        return (
          d.getFullYear() +
          "-" +
          String(d.getMonth() + 1).padStart(2, "0") +
          "-" +
          String(d.getDate()).padStart(2, "0")
        );
      },

      fmtQrBadge: function (sIssued) {
        if (sIssued === "X") {
          return "<span class='qrBadge qrBadge--issued'>발행완료</span>";
        }
        return "<span class='qrBadge qrBadge--new'>미발행</span>";
      },

      // 수량 포맷: 천단위 콤마, 불필요한 .000 제거 (소수가 있으면 표시)
      fmtQty: function (v) {
        return Number(v || 0).toLocaleString("ko-KR", {
          maximumFractionDigits: 3,
        });
      },
    });
  },
);
