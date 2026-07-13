sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter",
    "sap/m/ColumnListItem",
    "sap/m/Text",
    "sap/m/ObjectNumber",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/BusyDialog"
], function (
    Controller,
    Filter,
    FilterOperator,
    Sorter,
    ColumnListItem,
    Text,
    ObjectNumber,
    MessageToast,
    MessageBox,
    BusyDialog
) {
    "use strict";

    return Controller.extend("c1.mm.c1mmqr.controller.qrHistView", {

        _oSelectedData: null,

        onInit: function () {
            var oRouter = this.getOwnerComponent().getRouter();
            oRouter.getRoute("RouteqrHist").attachPatternMatched(this._onRoute, this);
        },

        _onRoute: function () {
            this._loadList();
        },

        onNavBack: function () {
            this.getOwnerComponent().getRouter().navTo("RouteqrView");
        },

        // ── 조회 ───────────────────────────────────────────────

        _buildFilters: function () {
            var aFilters = [];

            var sQrNo   = this.byId("hsfQrNo").getValue().trim();
            var sMatnr  = this.byId("hsfMatnr").getValue().trim();
            var sEbeln  = this.byId("hsfEbeln").getValue().trim();
            var sCharg  = this.byId("hsfCharg").getValue().trim();
            var sStatus = this.byId("hselStatus").getSelectedKey();
            var sFrom   = this.byId("hdpFrom").getValue();
            var sTo     = this.byId("hdpTo").getValue();

            if (sQrNo)  aFilters.push(new Filter("QrNo",  FilterOperator.Contains, sQrNo));
            if (sMatnr) aFilters.push(new Filter("Matnr", FilterOperator.Contains, sMatnr));
            if (sEbeln) aFilters.push(new Filter("Ebeln", FilterOperator.Contains, sEbeln));
            if (sCharg) aFilters.push(new Filter("Charg", FilterOperator.Contains, sCharg));
            if (sStatus !== "ALL") aFilters.push(new Filter("QrStatus", FilterOperator.EQ, sStatus));
            if (sFrom)  aFilters.push(new Filter("Erdat", FilterOperator.GE, this._toEdmDate(sFrom)));
            if (sTo)    aFilters.push(new Filter("Erdat", FilterOperator.LE, this._toEdmDate(sTo)));

            return aFilters;
        },

        _toEdmDate: function (sYyyymmdd) {
            if (!sYyyymmdd || sYyyymmdd.length < 8) return null;
            var y = parseInt(sYyyymmdd.substring(0, 4), 10);
            var m = parseInt(sYyyymmdd.substring(4, 6), 10) - 1;
            var d = parseInt(sYyyymmdd.substring(6, 8), 10);
            return new Date(y, m, d);
        },

        _loadList: function () {
            var oTable = this.byId("histTable");
            if (!oTable) return;

            var aFilters = this._buildFilters();
            var oSorter  = new Sorter("Erdat", true);

            oTable.setBusy(true);
            oTable.unbindItems();

            oTable.bindItems({
                path: "/QrHist",
                filters: aFilters,
                sorter: oSorter,
                template: this._getTemplate(),
                templateShareable: false,
                events: {
                    dataReceived: function (oEvent) {
                        oTable.setBusy(false);
                        var oData = oEvent.getParameter("data");
                        if (oData && oData.error) {
                            MessageToast.show("이력 조회 중 오류가 발생했습니다.");
                        }
                        var nCnt = oTable.getItems().length;
                        this.byId("hListSubHeader").setText(nCnt + "건 조회됨");
                        this.byId("btnDeleteQr").setEnabled(false);
                        this.byId("btnPrintLabel").setEnabled(false);
                    }.bind(this)
                }
            });
        },

        _getTemplate: function () {
            var that = this;
            return new ColumnListItem({
                type: "Active",
                press: function (oEvent) {
                    var oCtx = oEvent.getSource().getBindingContext();
                    if (oCtx) that._showDetail(oCtx.getObject());
                },
                cells: [
                    new Text({ text: "{QrNo}", wrapping: false }),
                    new Text({ text: "{Matnr}", wrapping: false }),
                    new Text({ text: "{Maktx}" }),              // 자재명만 줄바꿈 허용
                    new Text({ text: "{Charg}", wrapping: false }),
                    new ObjectNumber({
                        number: { path: "GrQty", formatter: that.fmtQty },
                        unit: "{Meins}"
                    }),
                    new Text({
                        text: { path: "Erdat", formatter: that.fmtDate.bind(that) },
                        wrapping: false   // 날짜는 항상 한 줄
                    }),
                    new sap.ui.core.HTML({
                        content: { path: "QrStatus", formatter: that.fmtStatusBadge.bind(that) },
                        preferDOM: false
                    })
                ]
            });
        },

        onSearch: function () {
            this._loadList();
            this._hideDetail();
        },

        onReset: function () {
            this.byId("hsfQrNo").setValue("");
            this.byId("hsfMatnr").setValue("");
            this.byId("hsfEbeln").setValue("");
            this.byId("hsfCharg").setValue("");
            this.byId("hselStatus").setSelectedKey("ALL");
            this.byId("hdpFrom").setValue("");
            this.byId("hdpTo").setValue("");
            this._loadList();
            this._hideDetail();
        },

        // ── 상세 ───────────────────────────────────────────────

        onHistRowSelect: function (oEvent) {
            var oTable    = this.byId("histTable");
            var aSelected = oTable.getSelectedItems();

            this.byId("btnDeleteQr").setEnabled(aSelected.length > 0);
            this.byId("btnPrintLabel").setEnabled(aSelected.length > 0);

            var oItem = oEvent.getParameter("listItem");
            if (oItem) {
                var oCtx = oItem.getBindingContext();
                if (oCtx) this._showDetail(oCtx.getObject());
            }
        },

        onHistRowPress: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext();
            if (oCtx) this._showDetail(oCtx.getObject());
        },

        // ── 라벨 인쇄 (브라우저 인쇄 → PDF 저장 가능) ──────────

        onPrintLabels: function () {
            var oTable    = this.byId("histTable");
            var aSelected = oTable.getSelectedItems();
            if (aSelected.length === 0) return;

            var aLabels = aSelected.map(function (oItem) {
                var o = oItem.getBindingContext().getObject();
                return {
                    QrNo:  o.QrNo,
                    Matnr: o.Matnr,
                    Maktx: o.Maktx,
                    Charg: o.Charg,
                    Menge: o.GrQty,
                    Meins: o.Meins,
                    Mblnr: o.Mblnr,
                    Ebeln: o.Ebeln
                };
            });

            this._printLabels(aLabels);
        },

        _printLabels: function (aLabels) {
            var that = this;

            var fnEsc = function (s) {
                return String(s == null ? "" : s)
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;");
            };

            var sLabelsHtml = aLabels.map(function (o) {
                var sQty = o.Menge != null
                    ? that.fmtQty(o.Menge) + " " + (o.Meins || "")
                    : "-";
                return (
                    "<div class='label'>" +
                    "<div class='qrbox' data-text='" + fnEsc(that._buildQrUrl(o.QrNo)) + "'></div>" +
                    "<div class='qrno'>" + fnEsc(o.QrNo) + "</div>" +
                    "<table class='info'>" +
                    "<tr><td>자재</td><td>" + fnEsc(o.Matnr) + "</td></tr>" +
                    "<tr><td>품명</td><td>" + fnEsc(o.Maktx) + "</td></tr>" +
                    "<tr><td>배치</td><td>" + fnEsc(o.Charg) + "</td></tr>" +
                    "<tr><td>수량</td><td>" + fnEsc(sQty) + "</td></tr>" +
                    "<tr><td>입고문서</td><td>" + fnEsc(o.Mblnr) + "</td></tr>" +
                    "<tr><td>PO</td><td>" + fnEsc(o.Ebeln) + "</td></tr>" +
                    "</table>" +
                    "</div>"
                );
            }).join("");

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
                "<div class='sheet'>" + sLabelsHtml + "</div>" +
                "<scr" + "ipt src='https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js'></scr" + "ipt>" +
                "<scr" + "ipt>" +
                "window.onload=function(){" +
                "var els=document.querySelectorAll('.qrbox');" +
                "for(var i=0;i<els.length;i++){" +
                "new QRCode(els[i],{text:els[i].getAttribute('data-text')," +
                "width:110,height:110,correctLevel:QRCode.CorrectLevel.M});}" +
                "setTimeout(function(){window.print();},600);" +
                "};" +
                "</scr" + "ipt>" +
                "</body></html>";

            var oWin = window.open("", "_blank", "width=900,height=700");
            if (!oWin) {
                MessageToast.show("팝업이 차단되었습니다. 브라우저 팝업 허용 후 다시 시도하세요.");
                return;
            }
            oWin.document.write(sHtml);
            oWin.document.close();
        },

        // ── 발행취소(삭제) ─────────────────────────────────────

        onDeleteQr: function () {
            var oTable    = this.byId("histTable");
            var aSelected = oTable.getSelectedItems();
            if (aSelected.length === 0) return;

            var aData = aSelected.map(function (oItem) {
                return oItem.getBindingContext().getObject();
            });

            var sMsg = aData.length === 1
                ? "QR번호 " + aData[0].QrNo + " 발행을 취소(삭제)하시겠습니까?"
                : aData.length + "건의 QR 발행을 취소(삭제)하시겠습니까?";

            MessageBox.confirm(sMsg, {
                title: "발행취소 확인",
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) {
                        this._doDelete(aData);
                    }
                }.bind(this)
            });
        },

        _doDelete: function (aDataList) {
            var oBusy  = new BusyDialog({ text: "발행취소 중..." });
            var oModel = this.getOwnerComponent().getModel();
            oModel.setUseBatch(false);   // 배치 끄고 즉시 개별 전송
            oBusy.open();

            var aPromises = aDataList.map(function (oData) {
                return new Promise(function (resolve) {
                    var sPath = "/QrHist('" + encodeURIComponent(oData.QrNo) + "')";
                    oModel.remove(sPath, {
                        success: function () { resolve({ ok: true }); },
                        error:   function () { resolve({ ok: false, qrNo: oData.QrNo }); }
                    });
                });
            });

            Promise.all(aPromises).then(function (aResults) {
                oBusy.close();
                var nOk   = aResults.filter(function (r) { return r.ok; }).length;
                var nFail = aResults.length - nOk;

                if (nFail === 0) {
                    MessageToast.show(nOk + "건 발행취소 완료");
                } else {
                    MessageBox.warning(nOk + "건 성공 / " + nFail + "건 실패");
                }
                this.byId("btnDeleteQr").setEnabled(false);
                this._loadList();
                this._hideDetail();
            }.bind(this));
        },

        _showDetail: function (oData) {
            this._oSelectedData = oData;

            this.byId("hEmptyDetail").setVisible(false);
            this.byId("hDetailPanel").setVisible(true);

            this.byId("hdMatnr").setText(oData.Matnr || "");
            this.byId("hdMaktx").setText(oData.Maktx || "");
            this.byId("hdStatusBadge").setContent(this.fmtStatusBadge(oData.QrStatus));
            this.byId("hdLgort").setText("저장위치: " + (oData.Lgort || "-"));
            this.byId("hdErdat").setText("QR 발행일: " + this.fmtDate(oData.Erdat));
            this.byId("hdMenge").setText(
                "입고수량 " + this.fmtQty(oData.GrQty) + " " + (oData.Meins || "")
            );
            this.byId("hdEbeln").setText(oData.Ebeln || "");
            this.byId("hdMblnr").setText(oData.Mblnr || "");
            this.byId("hdCharg").setText(oData.Charg || "");
            this.byId("hdVenName").setText(oData.VenName || "");
            // HR 이름 우선, 없으면 사용자ID
            this.byId("hdErnam").setText(oData.ErnamName || oData.Ernam || "");
            this.byId("hdQrNoText").setText("QR번호: " + (oData.QrNo || ""));

            this._renderQrCode(oData.QrNo || "");
            this._loadGrSummary(oData);
        },

        // ── 입고 요약 (건수 · 누적 · 기간) ──────────────────────
        _loadGrSummary: function (oData) {
            var oCnt = this.byId("hdGrCount"),
                oSum = this.byId("hdGrSum"),
                oPer = this.byId("hdGrPeriod");
            oCnt.setText("-"); oSum.setText("-"); oPer.setText("-");
            if (!oData.Charg) { return; }

            this.getOwnerComponent().getModel().read("/BatchHist", {
                filters: [
                    new Filter("Charg", FilterOperator.EQ, oData.Charg),
                    new Filter("Matnr", FilterOperator.EQ, oData.Matnr),
                    new Filter({
                        filters: [
                            new Filter("Bwart", FilterOperator.EQ, "101"),
                            new Filter("Bwart", FilterOperator.EQ, "131")
                        ], and: false
                    })
                ],
                success: function (oResult) {
                    var a = (oResult && oResult.results) || [];
                    if (!a.length) { oCnt.setText("0건"); oSum.setText("0"); oPer.setText("-"); return; }
                    var nSum = 0, sMeins = "";
                    a.forEach(function (r) { nSum += parseFloat(r.Menge || 0); sMeins = r.Meins || sMeins; });
                    var aDates = a.map(function (r) { return r.Bldat || r.Budat; }).filter(Boolean);
                    oCnt.setText(a.length + "건");
                    oSum.setText(this.fmtQty(nSum) + " " + sMeins);
                    if (aDates.length) {
                        var aTimes = aDates.map(function (d) { return new Date(d).getTime(); });
                        var dMin = aDates[aTimes.indexOf(Math.min.apply(null, aTimes))];
                        var dMax = aDates[aTimes.indexOf(Math.max.apply(null, aTimes))];
                        oPer.setText(this.fmtDate(dMin) + " ~ " + this.fmtDate(dMax));
                    } else { oPer.setText("-"); }
                }.bind(this),
                error: function () { /* BatchHist 미연동 시 - 유지 */ }
            });
        },

        _hideDetail: function () {
            this._oSelectedData = null;
            this.byId("hEmptyDetail").setVisible(true);
            this.byId("hDetailPanel").setVisible(false);
        },

        // ── 현재고 비교 ────────────────────────────────────────

        _loadBatchStock: function (oData) {
            if (!oData.Matnr || !oData.Werks) return;

            var oModel = this.getOwnerComponent().getModel();
            var oTable = this.byId("hdStockTable");
            oTable.destroyItems();

            var aFilters = [
                new Filter("Matnr", FilterOperator.EQ, oData.Matnr),
                new Filter("Werks", FilterOperator.EQ, oData.Werks)
            ];
            if (oData.Charg) {
                aFilters.push(new Filter("Charg", FilterOperator.EQ, oData.Charg));
            }

            oModel.read("/BatchStock", {
                filters: aFilters,
                success: function (oResult) {
                    var aRows = oResult.results || [];

                    aRows.forEach(function (oRow) {
                        oTable.addItem(this._buildStockRow(oRow, oData.Lgort));
                    }.bind(this));
                }.bind(this),
                error: function () {
                    MessageToast.show("현재고 조회 실패");
                }
            });
        },

        // 상태별 현재고 행 생성 (Clabs/Cinsm/Cspem/Umlme)
        _buildStockRow: function (oRow, sCurrentLgort) {
            var nClabs = parseFloat(oRow.Clabs || 0);
            var nCinsm = parseFloat(oRow.Cinsm || 0);
            var nCspem = parseFloat(oRow.Cspem || 0);
            var nUmlme = parseFloat(oRow.Umlme || 0);
            var nTotal = nClabs + nCinsm + nCspem + nUmlme;
            var bCurrent = oRow.Lgort === sCurrentLgort;

            return new ColumnListItem({
                highlight: bCurrent ? "Success" : "None",
                cells: [
                    new Text({ text: oRow.Lgort }),
                    new ObjectNumber({
                        number: this.fmtQty(nTotal),
                        emphasized: bCurrent,
                        state: nTotal > 0 ? "Success" : "None"
                    }),
                    new ObjectNumber({
                        number: this.fmtQty(nClabs),
                        state: nClabs > 0 ? "Success" : "None"
                    }),
                    new ObjectNumber({
                        number: this.fmtQty(nCinsm),
                        state: nCinsm > 0 ? "Warning" : "None"
                    }),
                    new ObjectNumber({
                        number: this.fmtQty(nCspem),
                        state: nCspem > 0 ? "Error" : "None"
                    }),
                    new Text({ text: oRow.Meins })
                ]
            });
        },

        // ── QR 렌더링 ──────────────────────────────────────────

        _iQrSeq: 0,

        // 배포된 앱 주소 — QR에 이 URL이 인코딩됨 (SAP HTTPS 44300)
        QR_BASE_URL: "https://61.97.134.34:44300/sap/bc/ui5_ui5/sap/zc1mmqr/index.html",

        _buildQrUrl: function (sQrNo) {
            return this.QR_BASE_URL + "#/scan/" + encodeURIComponent(sQrNo);
        },

        _renderQrCode: function (sQrNo) {
            if (!sQrNo) return;

            var iMySeq = ++this._iQrSeq;
            var sQrText = this._buildQrUrl(sQrNo);

            // preferDOM=true HTML 컨트롤은 setContent로 DOM이 안 바뀌므로 직접 조작
            var oDomNow = document.getElementById("hdQrCodeDiv");
            if (oDomNow) {
                oDomNow.innerHTML = "";
            }

            setTimeout(function () {
                if (iMySeq !== this._iQrSeq) return;

                var oDom = document.getElementById("hdQrCodeDiv");
                if (!oDom) return;
                oDom.innerHTML = "";

                var fnDraw = function () {
                    if (iMySeq !== this._iQrSeq) return;
                    oDom.innerHTML = "";
                    new QRCode(oDom, {
                        text: sQrText,
                        width: 140,
                        height: 140,
                        colorDark: "#000000",
                        colorLight: "#ffffff",
                        correctLevel: QRCode.CorrectLevel.M
                    });
                }.bind(this);

                if (typeof QRCode !== "undefined") {
                    fnDraw();
                } else {
                    var oScript = document.createElement("script");
                    oScript.src = "https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js";
                    oScript.onload = fnDraw;
                    document.head.appendChild(oScript);
                }
            }.bind(this), 200);
        },

        // ── 포맷터 ─────────────────────────────────────────────

        fmtDate: function (oDate) {
            if (!oDate) return "-";
            var d = oDate instanceof Date ? oDate : new Date(oDate);
            if (isNaN(d.getTime())) return "-";
            return d.getFullYear() + "-" +
                   String(d.getMonth() + 1).padStart(2, "0") + "-" +
                   String(d.getDate()).padStart(2, "0");
        },

        fmtStatusBadge: function (sStatus) {
            if (sStatus === "I") {
                return "<span class='qrBadge qrBadge--issued'>발행완료</span>";
            }
            return "<span class='qrBadge qrBadge--new'>미발행</span>";
        },

        // 수량 포맷: 천단위 콤마, 불필요한 .000 제거
        fmtQty: function (v) {
            return Number(v || 0).toLocaleString("ko-KR", {
                maximumFractionDigits: 3
            });
        }

    });
});
