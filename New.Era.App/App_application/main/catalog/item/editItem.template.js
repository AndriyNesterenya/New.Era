define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TItem.$Title'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Item.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
