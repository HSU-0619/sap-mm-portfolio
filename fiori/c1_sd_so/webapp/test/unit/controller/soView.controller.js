/*global QUnit*/

sap.ui.define([
	"c1/sd/c1sdso/controller/soView.controller"
], function (Controller) {
	"use strict";

	QUnit.module("soView Controller");

	QUnit.test("I should test the soView controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
