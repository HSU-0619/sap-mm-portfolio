/*global QUnit*/

sap.ui.define([
	"c1/mm/c1mmpoappr/controller/approvalView.controller"
], function (Controller) {
	"use strict";

	QUnit.module("approvalView Controller");

	QUnit.test("I should test the approvalView controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
