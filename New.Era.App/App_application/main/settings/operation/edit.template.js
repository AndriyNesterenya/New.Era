define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]'; },
            'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
            'TOpTrans.$DtAccDisabled'() { return !this.Plan.Id || !!this.DtAccMode; }
        },
        defaults: {
            "Operation.Menu"() { return this.Params.ParentMenu; }
        },
        validators: {
            'Operation.Form': '@[Error.Required]',
            'Operation.Name': '@[Error.Required]'
        },
        events: {
            'Operation.Form.change': formChange,
            'Operation.Trans[].DtAccMode.change'(elem) { elem.Dt.$empty(); },
            'Operation.Trans[].CtAccMode.change'(elem) { elem.Ct.$empty(); }
        }
    };
    exports.default = template;
    function formChange() {
    }
});
