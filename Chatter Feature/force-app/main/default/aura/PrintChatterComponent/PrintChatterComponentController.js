({
    handleClick : function(c, e, h) {
        window.open("/apex/PrintChatterPage?recordName=" + c.get('v.accountRecord')[0].Name + "&SobjectId=" + c.get('v.recordId') + "", '_blank');
    }
})