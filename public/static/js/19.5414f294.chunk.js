(this.webpackJsonp=this.webpackJsonp||[]).push([[19],{640:function(e,n,t){"use strict";t.d(n,"a",(function(){return b}));var r=t(4),l=t.n(r),i=t(0),o=t(2),a=t(284),c=t(282),u=t(24),s=t(285),d=t(97),p=t(116),f=t(332);function m(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function g(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?m(Object(t),!0).forEach((function(n){l()(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):m(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function b(e){var n,t,r,l,m,b,v,y,O=Object(p.a)(d.a.ActAsRigInspector);return null!=(n=e.config)&&n.valueType&&"string"===(null==(t=e.config)?void 0:t.valueType)?i.createElement(o.a,{style:{flex:1}},i.createElement(a.a,{mode:"outlined",disabled:!O,style:{marginVertical:8},value:e.value,onChangeText:function(n){return e.onChange(g(g({},e.config),{},{value:n}))},label:e.config.label||""}),i.createElement(c.a,{type:"info"},e.config.description||"No description")):null!=(r=e.config)&&r.valueType&&"boolean"===(null==(l=e.config)?void 0:l.valueType)?i.createElement(u.b.Item,{title:e.config.label||"",disabled:!O,description:e.config.description,style:{marginVertical:8},right:function(){return i.createElement(s.a.Android,{status:e.value?"checked":"unchecked"})},onPress:function(){return e.onChange(g(g({},e.config),{},{value:!e.value}))}}):null!=(m=e.config)&&m.valueType&&"integer"===(null==(b=e.config)?void 0:b.valueType)?i.createElement(o.a,{style:{flex:1}},i.createElement(a.a,{disabled:!O,value:e.value,mode:"outlined",onChangeText:function(n){return e.onChange(g(g({},e.config),{},{value:n}))},label:e.config.label||"",keyboardType:"number-pad",style:{marginVertical:8}}),i.createElement(c.a,{type:"info"},e.config.description||"No description")):null!=(v=e.config)&&v.valueType&&"date"===(null==(y=e.config)?void 0:y.valueType)?i.createElement(o.a,{style:{flex:1}},i.createElement(f.a,{disabled:!O,timestamp:Number(e.value),onChange:function(n){return e.onChange(g(g({},e.config),{},{value:n.toString()}))},label:e.config.label||""}),i.createElement(c.a,{type:"info"},e.config.description||"No description")):null}},785:function(e,n,t){"use strict";t.r(n),t.d(n,"default",(function(){return V}));var r=t(11),l=t.n(r),i=t(36),o=t.n(i),a=t(8),c=t.n(a),u=t(47),s=t(37),d=t(0),p=t(104),f=t(202),m=t(23),g=t.n(m),b=t(4),v=t.n(b),y=t(1),O=t(2),E=t(7),T=t(640),h=t(160),j=t(375),I=t(253),P=t(395),w=t(284),x=t(285),k=t(396);function C(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function S(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?C(Object(t),!0).forEach((function(n){v()(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):C(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function z(){var e,n=Object(E.c)((function(e){return e.forms.rigInspectionTemplate})),t=d.useState(null),r=l()(t,2),i=r[0],o=r[1],a=d.useState(!1),c=l()(a,2),u=c[0],s=c[1],p=Object(E.b)();return d.createElement(d.Fragment,null,null==(e=n.fields)?void 0:e.map((function(e,t){return d.createElement(d.Fragment,null,d.createElement(O.a,{style:{display:"flex",flexDirection:"row",alignItems:"center"}},d.createElement(O.a,{style:{flexGrow:1},onTouchEnd:function(){return o(S(S({},e),{},{index:t}))}},d.createElement(T.a,{config:e,value:(null==e?void 0:e.value)||"",onChange:function(){return null}})),d.createElement(h.a,{icon:"delete",onPress:function(){return p(E.a.forms.rigInspectionTemplate.setFields(n.fields.filter((function(e,n){return n!==t}))))}})),d.createElement(j.a,null))})),d.createElement(I.a,null,d.createElement(P.a,{visible:!!i},d.createElement(P.a.Title,null,"New field"),d.createElement(P.a.Content,null,d.createElement(w.a,{label:"Name",mode:"outlined",value:null==i?void 0:i.label,onChangeText:function(e){return o(S(S({},i),{},{label:e}))}}),d.createElement(w.a,{label:"Description",placeholder:"optional",mode:"outlined",value:null==i?void 0:i.description,onChangeText:function(e){return o(S(S({},i),{},{description:e}))}}),d.createElement(x.a.Item,{label:"This is a required field",mode:"android",onPress:function(){return o(S(S({},i),{},{isRequired:!(null!=i&&i.isRequired)}))},status:null!=i&&i.isRequired?"checked":"unchecked"})),d.createElement(P.a.Actions,null,d.createElement(f.a,{onPress:function(){return o(null)}},"Cancel"),d.createElement(f.a,{onPress:function(){void 0!==(null==i?void 0:i.index)?p(E.a.forms.rigInspectionTemplate.setFields(n.fields.map((function(e,n){return n===i.index?i:e})))):p(E.a.forms.rigInspectionTemplate.setFields([].concat(g()(n.fields),[i]))),o(null)}},"Save"))),d.createElement(k.a.Group,{open:u,visible:!0,icon:u?"close":"plus",actions:[{icon:"pencil",label:"Text",onPress:function(){return o({valueType:"string"})}},{icon:"calendar",label:"Date",onPress:function(){return o({valueType:"date"})}},{icon:"counter",label:"Number",onPress:function(){return o({valueType:"integer"})}},{icon:"checkbox-marked-circle-outline",label:"Checkbox",onPress:function(){return o({valueType:"boolean"})}}],onStateChange:function(e){var n=e.open;return s(n)}})))}y.a.create({fields:{flex:1},field:{marginBottom:8}});var N,D,F=t(158),$=t(327),R=t(97),q=t(116),A=Object(s.a)(N||(N=o()(["\n  query RigInspection($dropzoneId: Int!) {\n    dropzone(id: $dropzoneId) {\n      id\n      rigInspectionTemplate {\n        id\n        name\n        definition\n      }\n    }\n  }\n"]))),J=Object(s.a)(D||(D=o()(["\n  mutation UpdateRigInspectionTemplate(\n    $dropzoneId: Int,\n    $formId: Int,\n    $definition: String\n  ) {\n    updateFormTemplate(input: {\n      id: $formId\n      attributes: {\n        dropzoneId: $dropzoneId,\n        definition: $definition\n      }\n    }) {\n      formTemplate {\n        id\n        name\n        definition\n      }\n      fieldErrors {\n        field\n        message\n      }\n      errors\n    }\n  }\n"])));function V(){var e,n,t,r,i=Object(E.c)((function(e){return e.forms.rigInspectionTemplate})),o=Object($.a)(),a=Object(E.b)(),s=Object(u.useQuery)(A,{variables:{dropzoneId:Number(null==o||null==(e=o.dropzone)?void 0:e.id)}}),m=s.data,g=(s.loading,Object(q.a)(R.a.UpdateFormTemplate)),b=Object(u.useMutation)(J),v=l()(b,2),y=v[0],O=v[1];d.useEffect((function(){var e;null!=m&&null!=(e=m.dropzone)&&e.rigInspectionTemplate&&a(E.a.forms.rigInspectionTemplate.setOpen(m.dropzone.rigInspectionTemplate))}),[JSON.stringify(null==m||null==(n=m.dropzone)?void 0:n.rigInspectionTemplate)]);var T=d.useCallback((function(){var e;return c.a.async((function(n){for(;;)switch(n.prev=n.next){case 0:return n.prev=0,n.next=3,c.a.awrap(y({variables:{formId:Number(null==m?void 0:m.dropzone.rigInspectionTemplate.id),dropzoneId:Number(null==m||null==(e=m.dropzone)?void 0:e.id),definition:JSON.stringify(i.fields)}}));case 3:a(E.a.notifications.showSnackbar({message:"Template saved",variant:"success"})),n.next=9;break;case 6:n.prev=6,n.t0=n.catch(0),a(E.a.notifications.showSnackbar({message:n.t0.message,variant:"error"}));case 9:case"end":return n.stop()}}),null,null,[[0,6]],Promise)}),[JSON.stringify(i.fields),null==i||null==(t=i.original)?void 0:t.id,null==o||null==(r=o.dropzone)?void 0:r.id]);return d.createElement(F.a,null,d.createElement(p.a,{style:{width:"100%"}},d.createElement(p.a.Title,{title:"Rig Inspection Form Template"}),d.createElement(p.a.Content,null,d.createElement(z,null)),d.createElement(p.a.Actions,null,d.createElement(f.a,{disabled:!g,mode:"contained",loading:O.loading,onPress:function(){return T()},style:{width:"100%"}},"Save template"))))}}}]);
//# sourceMappingURL=19.5414f294.chunk.js.map