sap.ui.define([
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/ui/core/HTML",
    "sap/m/MessageBox"
], function (Dialog, Button, HTML, MessageBox) {
    "use strict";

    /**
     * 브라우저 카메라 기반 QR 스캐너
     * - getUserMedia 로 카메라 권한 요청 → 허용 시 카메라 표시
     * - BarcodeDetector(크롬/안드로이드) 우선, 미지원이면 jsQR(CDN) 폴백
     * - 주의: 카메라는 HTTPS 또는 localhost 에서만 동작 (브라우저 보안 정책)
     */
    var CameraScanner = {

        _stream: null,
        _timer: null,

        /**
         * @param {function} fnSuccess - 인식된 텍스트를 받는 콜백
         */
        scan: function (fnSuccess) {
            var that = this;

            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                MessageBox.warning(
                    "이 접속 환경에서는 브라우저가 카메라를 차단합니다.\n" +
                    "(카메라는 보안 정책상 https:// 또는 localhost 에서만 허용)\n\n" +
                    "▶ 지금 바로 스캔하려면:\n" +
                    "  휴대폰 기본 카메라 앱으로 QR 라벨을 찍으면\n" +
                    "  이 화면으로 자동 연결됩니다.\n\n" +
                    "▶ 또는 QR번호를 아래 입력칸에 직접 입력하세요.",
                    { title: "카메라 사용 불가" }
                );
                return;
            }

            var oDialog = new Dialog({
                title: "QR 코드 스캔",
                contentWidth: "24rem",
                content: [
                    new HTML({
                        content:
                            "<div class='camScanBox'>" +
                            "<video id='camScanVideo' autoplay playsinline muted></video>" +
                            "<div class='camScanFrame'>" +
                            "<div class='camScanLine'></div>" +
                            "</div>" +
                            "</div>" +
                            "<div class='camScanHint'>QR 코드를 사각형 안에 맞춰주세요</div>"
                    })
                ],
                endButton: new Button({
                    text: "닫기",
                    press: function () {
                        oDialog.close();
                    }
                }),
                afterClose: function () {
                    that._stop();
                    oDialog.destroy();
                }
            });

            oDialog.open();

            // 다이얼로그 렌더링 후 카메라 시작 (이 시점에 권한 팝업이 뜸)
            setTimeout(function () {
                that._start(oDialog, fnSuccess);
            }, 300);
        },

        _start: function (oDialog, fnSuccess) {
            var that = this;

            navigator.mediaDevices
                .getUserMedia({
                    video: { facingMode: "environment" }   // 후면 카메라 우선
                })
                .then(function (oStream) {
                    that._stream = oStream;
                    var oVideo = document.getElementById("camScanVideo");
                    if (!oVideo) {
                        that._stop();
                        return;
                    }
                    oVideo.srcObject = oStream;
                    that._detect(oVideo, oDialog, fnSuccess);
                })
                .catch(function (oErr) {
                    oDialog.close();
                    if (oErr && oErr.name === "NotAllowedError") {
                        MessageBox.warning("카메라 권한이 거부되었습니다.\n브라우저 주소창의 카메라 아이콘에서 허용으로 변경해 주세요.");
                    } else {
                        MessageBox.error("카메라를 시작할 수 없습니다.\n" + (oErr.message || oErr));
                    }
                });
        },

        _detect: function (oVideo, oDialog, fnSuccess) {
            var that = this;

            var fnFinish = function (sText) {
                that._stop();
                oDialog.close();
                fnSuccess(sText);
            };

            if (window.BarcodeDetector) {
                // 크롬/엣지/안드로이드 내장 감지기
                var oDetector = new window.BarcodeDetector({ formats: ["qr_code"] });
                that._timer = setInterval(function () {
                    oDetector
                        .detect(oVideo)
                        .then(function (aCodes) {
                            if (aCodes.length > 0 && aCodes[0].rawValue) {
                                fnFinish(aCodes[0].rawValue);
                            }
                        })
                        .catch(function () { /* 프레임 미준비 - 무시 */ });
                }, 300);
            } else {
                // 폴백: jsQR (iOS Safari 등)
                var fnRun = function () {
                    var oCanvas = document.createElement("canvas");
                    var oCtx = oCanvas.getContext("2d", { willReadFrequently: true });

                    that._timer = setInterval(function () {
                        if (oVideo.readyState !== 4) return;
                        oCanvas.width = oVideo.videoWidth;
                        oCanvas.height = oVideo.videoHeight;
                        oCtx.drawImage(oVideo, 0, 0);
                        var oImg = oCtx.getImageData(0, 0, oCanvas.width, oCanvas.height);
                        var oCode = window.jsQR(oImg.data, oImg.width, oImg.height);
                        if (oCode && oCode.data) {
                            fnFinish(oCode.data);
                        }
                    }, 350);
                };

                if (window.jsQR) {
                    fnRun();
                } else {
                    var oScript = document.createElement("script");
                    oScript.src = "https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js";
                    oScript.onload = fnRun;
                    document.head.appendChild(oScript);
                }
            }
        },

        _stop: function () {
            if (this._timer) {
                clearInterval(this._timer);
                this._timer = null;
            }
            if (this._stream) {
                this._stream.getTracks().forEach(function (oTrack) {
                    oTrack.stop();
                });
                this._stream = null;
            }
        }
    };

    return CameraScanner;
});
