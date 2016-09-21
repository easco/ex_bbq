import "phoenix_html"
import CookingModule from "./cooking"

const modules = {
    CookingModule
};

function handleDOMContentLoaded() {
    const module_js_file = document.getElementsByTagName('body')[0].dataset.bbquiModuleName;
    if(modules[module_js_file]) {
        window.currentModule = new (modules[module_js_file])()
        window.currentModule.moduleWillShow()
    }
}

function handleDocumentUnload() {
    window.currentModule.moduleWillHide();
}

window.addEventListener('DOMContentLoaded', handleDOMContentLoaded, false);
window.addEventListener('unload', handleDocumentUnload, false);