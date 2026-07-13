/*global QUnit*/

sap.ui.define([
	"c1/mm/c1mmqr/controller/qrView.controller"
], function (Controller) {
	"use strict";

	QUnit.module("qrView Controller");

	QUnit.test("I should test the qrView controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
