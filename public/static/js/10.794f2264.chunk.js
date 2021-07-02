(this.webpackJsonp=this.webpackJsonp||[]).push([[10],{423:function(e,n,r){"use strict";var t=r(10),a=r.n(t),i=r(0),o=r(1),l=r(2),s=r(36),c=r(48);function u(){return(u=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var d=function(e){var n=e.children,r=e.style,t=e.numeric,o=a()(e,["children","style","numeric"]);return i.createElement(c.a,u({},o,{style:[p.container,t&&p.right,r]}),i.createElement(s.a,{numberOfLines:1},n))};d.displayName="DataTable.Cell";var p=o.a.create({container:{flex:1,flexDirection:"row",alignItems:"center"},right:{justifyContent:"flex-end"}}),m=d,f=r(16),g=r.n(f),b=r(23),y=r(14);function h(){return(h=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var v=function(e){var n=e.children,r=e.style,t=e.theme,o=a()(e,["children","style","theme"]),s=g()(t.dark?b.h:b.a).alpha(.12).rgb().string();return i.createElement(l.a,h({},o,{style:[E.header,{borderBottomColor:s},r]}),n)};v.displayName="DataTable.Header";var E=o.a.create({header:{flexDirection:"row",height:48,paddingHorizontal:16,borderBottomWidth:2*o.a.hairlineWidth}}),k=Object(y.c)(v),O=r(6),x=r(62),z=r(25),j=r(67);function S(){return(S=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var w=function(e){var n=e.numeric,r=e.children,t=e.onPress,o=e.sortDirection,c=e.theme,u=e.style,d=e.numberOfLines,p=void 0===d?1:d,m=a()(e,["numeric","children","onPress","sortDirection","theme","style","numberOfLines"]),f=i.useRef(new O.a.Value("ascending"===o?0:1)).current;i.useEffect((function(){O.a.timing(f,{toValue:"ascending"===o?0:1,duration:150,useNativeDriver:!0}).start()}),[o,f]);var b=g()(c.colors.text).alpha(.6).rgb().string(),y=f.interpolate({inputRange:[0,1],outputRange:["0deg","180deg"]}),h=o?i.createElement(O.a.View,{style:[C.icon,{transform:[{rotate:y}]}]},i.createElement(j.b,{name:"arrow-up",size:16,color:c.colors.text,direction:z.a.isRTL?"rtl":"ltr"})):null;return i.createElement(x.a,S({disabled:!t,onPress:t},m),i.createElement(l.a,{style:[C.container,n&&C.right,u]},h,i.createElement(s.a,{style:[C.cell,o?C.sorted:{color:b}],numberOfLines:p},r)))};w.displayName="DataTable.Title";var C=o.a.create({container:{flex:1,flexDirection:"row",alignContent:"center",paddingVertical:12},right:{justifyContent:"flex-end"},cell:{height:24,lineHeight:24,fontSize:12,fontWeight:"500",alignItems:"center"},sorted:{marginLeft:8},icon:{height:24,justifyContent:"center"}}),P=Object(y.c)(w),I=r(135);function T(){return(T=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var $=function(e){var n=e.label,r=e.page,t=e.numberOfPages,o=e.onPageChange,c=e.style,u=e.theme,d=a()(e,["label","page","numberOfPages","onPageChange","style","theme"]),p=g()(u.colors.text).alpha(.6).rgb().string();return i.createElement(l.a,T({},d,{style:[A.container,c]}),i.createElement(s.a,{style:[A.label,{color:p}],numberOfLines:1},n),i.createElement(I.a,{icon:function(e){var n=e.size,r=e.color;return i.createElement(j.b,{name:"chevron-left",color:r,size:n,direction:z.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===r,onPress:function(){return o(r-1)}}),i.createElement(I.a,{icon:function(e){var n=e.size,r=e.color;return i.createElement(j.b,{name:"chevron-right",color:r,size:n,direction:z.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===t||r===t-1,onPress:function(){return o(r+1)}}))};$.displayName="DataTable.Pagination";var A=o.a.create({container:{justifyContent:"flex-end",flexDirection:"row",alignItems:"center",paddingLeft:16},label:{fontSize:12,marginRight:44}}),R=Object(y.c)($);function D(){return(D=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var F=o.a.create({container:{borderStyle:"solid",borderBottomWidth:o.a.hairlineWidth,minHeight:48,paddingHorizontal:16},content:{flex:1,flexDirection:"row"}}),N=Object(y.c)((function(e){var n=e.onPress,r=e.style,t=e.theme,o=e.children,s=e.pointerEvents,u=a()(e,["onPress","style","theme","children","pointerEvents"]),d=g()(t.dark?b.h:b.a).alpha(.12).rgb().string();return i.createElement(c.a,D({},u,{onPress:n,style:[F.container,{borderBottomColor:d},r]}),i.createElement(l.a,{style:F.content,pointerEvents:s},o))}));function L(){return(L=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var r=arguments[n];for(var t in r)Object.prototype.hasOwnProperty.call(r,t)&&(e[t]=r[t])}return e}).apply(this,arguments)}var V=function(e){var n=e.children,r=e.style,t=a()(e,["children","style"]);return i.createElement(l.a,L({},t,{style:[H.container,r]}),n)};V.Header=k,V.Title=P,V.Row=N,V.Cell=m,V.Pagination=R;var H=o.a.create({container:{width:"100%"}});n.a=V},577:function(e,n,r){"use strict";r.d(n,"a",(function(){return d}));var t=r(0),a=r(1),i=r(126),o=r(221),l=r(359),s=r(352),c=r(173),u=r(5);function d(e){var n=e.buttonLabel,r=e.buttonAction,a=e.title,d=e.loading,p=e.children,m=Object(u.c)((function(e){return e.global}));return t.createElement(o.a,null,t.createElement(l.a,{visible:!!e.open,dismissable:!1,style:{maxWidth:500,alignSelf:"center"}},t.createElement(s.a,{indeterminate:!0,visible:d,color:m.theme.colors.accent}),t.createElement(l.a.Title,null,a),t.createElement(l.a.Content,{pointerEvents:"box-none"},t.createElement(l.a.ScrollArea,null,t.createElement(i.b,null,p))),t.createElement(l.a.Actions,{style:{justifyContent:"flex-end"}},t.createElement(c.a,{onPress:function(){e.onClose()}},"Cancel"),t.createElement(c.a,{onPress:r},n))))}a.a.create({button:{width:"100%",borderRadius:16,padding:5},contentContainer:{paddingHorizontal:16,paddingBottom:32},sheet:{elevation:3,backgroundColor:"white",flexGrow:1,height:"100%",display:"flex",flexDirection:"column",justifyContent:"center"},sheetHeader:{elevation:2,borderTopLeftRadius:20,borderTopRightRadius:20,height:40,shadowColor:"#000",shadowOffset:{width:0,height:-4},backgroundColor:"white",shadowOpacity:.22,shadowRadius:2.22}})},610:function(e,n,r){"use strict";r.d(n,"a",(function(){return T}));var t=r(3),a=r.n(t),i=r(9),o=r.n(i),l=r(31),s=r.n(l),c=r(4),u=r.n(c),d=r(38),p=r(0),m=r(5),f=r(1),g=r(2),b=r(251),y=r(249),h=r(294),v=r(291),E=r(97),k=r(81);function O(e){var n,r,t=Object(m.c)((function(e){return e.forms.rig})),a=Object(m.b)(),i=Object(E.a)(k.a.CreateRig);return p.createElement(g.a,null,p.createElement(b.a,{style:j.field,mode:"outlined",label:"Make",error:!!t.fields.make.error,value:t.fields.make.value||"",onChangeText:function(e){return a(m.a.forms.rig.setField(["make",e]))}}),p.createElement(y.a,{type:t.fields.make.error?"error":"info"},t.fields.make.error||"e.g Javelin, Mirage"),p.createElement(b.a,{style:j.field,mode:"outlined",label:"Model",error:!!t.fields.model.error,value:t.fields.model.value||"",onChangeText:function(e){return a(m.a.forms.rig.setField(["model",e]))}}),p.createElement(y.a,{type:t.fields.model.error?"error":"info"},t.fields.model.error||"e.g G4.1"),p.createElement(b.a,{style:j.field,mode:"outlined",label:"Serial",error:!!t.fields.serial.error,value:t.fields.serial.value||"",onChangeText:function(e){return a(m.a.forms.rig.setField(["serial",e]))}}),p.createElement(y.a,{type:t.fields.serial.error?"error":"info"},t.fields.serial.error||""),p.createElement(b.a,{style:j.field,mode:"outlined",label:"Current canopy size",error:!!t.fields.canopySize.error,value:(null==(n=t.fields.canopySize.value)?void 0:n.toString())||"",keyboardType:"number-pad",onChangeText:function(e){return a(m.a.forms.rig.setField(["canopySize",Number(e)]))}}),p.createElement(y.a,{type:t.fields.canopySize.error?"error":"info"},t.fields.canopySize.error||"Size of canopy in container"),e.showTypeSelect?p.createElement(v.a,{items:["student","sport","tandem"],renderItemLabel:function(e){return e},isDisabled:function(e){return!i&&"sport"!==e},selected:[(null==(r=t.fields.rigType)?void 0:r.value)||"sport"],onChangeSelected:function(e){var n=o()(e,1)[0];return a(m.a.forms.rig.setField(["rigType",n]))}}):null,p.createElement(h.a,{timestamp:t.fields.repackExpiresAt.value||(new Date).getTime()/1e3,onChange:function(e){return a(m.a.forms.rig.setField(["repackExpiresAt",e]))},label:"Reserve repack expiry date"}),p.createElement(y.a,{type:t.fields.repackExpiresAt.error?"error":"info"},t.fields.repackExpiresAt.error||""))}var x,z,j=f.a.create({fields:{flex:1},field:{marginBottom:8}}),S=r(577);function w(e,n){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var t=Object.getOwnPropertySymbols(e);n&&(t=t.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),r.push.apply(r,t)}return r}function C(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{};n%2?w(Object(r),!0).forEach((function(n){a()(e,n,r[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):w(Object(r)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(r,n))}))}return e}var P=Object(d.gql)(x||(x=s()(["\n  mutation CreateRig(\n    $make: String,\n    $model: String,\n    $serial: String,\n    $rigType: String,\n    $canopySize: Int,\n    $repackExpiresAt: Int\n    $userId: Int\n    $dropzoneId: Int\n  ) {\n    createRig(\n      input: {\n        attributes: {\n          make: $make\n          model: $model\n          serial: $serial\n          repackExpiresAt: $repackExpiresAt\n          dropzoneId: $dropzoneId\n          userId: $userId\n          canopySize: $canopySize\n          rigType: $rigType\n        }\n      }\n    ) {\n      errors\n      fieldErrors {\n        field\n        message\n      }\n      rig {\n        id\n        make\n        model\n        serial\n        canopySize\n        repackExpiresAt\n        packValue\n        maintainedAt\n        rigType\n\n        user {\n          id\n          rigs {\n            id\n            make\n            model\n            serial\n            canopySize\n            repackExpiresAt\n            packValue\n            maintainedAt\n          }\n        }\n      }\n    }\n  }\n"]))),I=Object(d.gql)(z||(z=s()(["\n  mutation UpdateRig(\n    $id: Int!\n    $make: String,\n    $model: String,\n    $serial: String,\n    $rigType: String,\n    $canopySize: Int,\n    $repackExpiresAt: Int\n    $userId: Int\n    $dropzoneId: Int\n  ) {\n    updateRig(\n      input: {\n        id: $id,\n        attributes: {\n          make: $make\n          model: $model\n          serial: $serial\n          repackExpiresAt: $repackExpiresAt\n          dropzoneId: $dropzoneId\n          userId: $userId\n          canopySize: $canopySize\n          rigType: $rigType\n        }\n      }\n    ) {\n      errors\n      fieldErrors {\n        field\n        message\n      }\n      rig {\n        id\n        make\n        model\n        serial\n        canopySize\n        repackExpiresAt\n        packValue\n        maintainedAt\n        rigType\n\n        user {\n          id\n          rigs {\n            id\n            make\n            model\n            serial\n            canopySize\n            repackExpiresAt\n            packValue\n            maintainedAt\n          }\n        }\n      }\n    }\n  }\n"])));function T(e){var n,r=e.open,t=(e.onClose,e.userId,e.dropzoneId,Object(m.b)()),a=Object(m.c)((function(e){return e.forms.rig})),i=Object(d.useMutation)(P),l=o()(i,2),s=l[0],c=l[1],f=Object(d.useMutation)(I),g=o()(f,2),b=g[0],y=g[1],h=c.loading||y.loading,v=p.useCallback((function(){var e=!1;return a.fields.make.value||(e=!0,t(m.a.forms.rig.setFieldError(["make","Required"]))),a.fields.model.value||(e=!0,t(m.a.forms.rig.setFieldError(["model","Required"]))),a.fields.serial.value||(e=!0,t(m.a.forms.rig.setFieldError(["serial","Required"]))),a.fields.canopySize.value||(e=!0,t(m.a.forms.rig.setFieldError(["canopySize","Required"]))),a.fields.repackExpiresAt.value||(e=!0,t(m.a.forms.rig.setFieldError(["repackExpiresAt","You must select a repack date in the future"]))),!e}),[JSON.stringify(a.fields)]),E=p.useCallback((function(){var n,r,i,o,l,c,d,p,f,g,y,h;return u.a.async((function(E){for(;;)switch(E.prev=E.next){case 0:if(v()){E.next=2;break}return E.abrupt("return");case 2:return E.prev=2,g=null!=(n=a.original)&&n.id?b:s,E.next=6,u.a.awrap(g({variables:C(C({},null!=(r=a.original)&&r.id?{id:Number(null==(i=a.original)?void 0:i.id)}:{}),{},{make:a.fields.make.value,model:a.fields.model.value,serial:a.fields.serial.value,canopySize:a.fields.canopySize.value,rigType:a.fields.rigType.value,repackExpiresAt:a.fields.repackExpiresAt.value,userId:e.userId?Number(e.userId):null,dropzoneId:e.dropzoneId?Number(e.dropzoneId):null})}));case 6:if(y=E.sent,null==(h=null!=(o=a.original)&&o.id?null==(l=y.data)?void 0:l.updateRig:null==(c=y.data)?void 0:c.createRig)||null==(d=h.fieldErrors)||d.map((function(e){var n=e.field,r=e.message;switch(n){case"make":return t(m.a.forms.rig.setFieldError(["make",r]));case"model":return t(m.a.forms.rig.setFieldError(["model",r]));case"serial":return t(m.a.forms.rig.setFieldError(["serial",r]));case"canopy_size":return t(m.a.forms.rig.setFieldError(["canopySize",r]));case"repack_expires_at":return t(m.a.forms.rig.setFieldError(["repackExpiresAt",r]));case"rig_type":return t(m.a.forms.rig.setFieldError(["rigType",r]))}})),null==h||null==(p=h.errors)||!p.length){E.next=11;break}return E.abrupt("return",t(m.a.notifications.showSnackbar({message:null==h?void 0:h.errors[0],variant:"error"})));case 11:null!=h&&null!=(f=h.fieldErrors)&&f.length||e.onSuccess(),E.next=17;break;case 14:E.prev=14,E.t0=E.catch(2),t(m.a.notifications.showSnackbar({message:E.t0.message,variant:"error"}));case 17:case"end":return E.stop()}}),null,null,[[2,14]],Promise)}),[JSON.stringify(a.fields),s,b,e.onSuccess]);return p.createElement(S.a,{title:null!=(n=a.original)&&n.id?"Edit rig":"New rig",open:r,snapPoints:[0,580],onClose:function(){e.onClose(),t(m.a.forms.rig.reset())},buttonAction:E,buttonLabel:"Save",loading:h},p.createElement(O,{showTypeSelect:!!e.dropzoneId}))}},732:function(e,n,r){"use strict";r.r(n),r.d(n,"default",(function(){return P}));var t,a,i=r(9),o=r.n(i),l=r(31),s=r.n(l),c=r(4),u=r.n(c),d=r(38),p=r(47),m=r(32),f=r(0),g=r(1),b=r(192),y=r(352),h=r(423),v=r(360),E=r(81),k=r(5),O=r(191),x=r(354),z=r(610),j=r(126),S=r(97),w=Object(m.a)(t||(t=s()(["\n  query QueryDropzoneRigs(\n    $dropzoneId: Int!\n  ) {\n    dropzone(id: $dropzoneId) {\n      id\n      rigs {\n        id\n        make\n        isPublic\n        model\n        serial\n        rigType\n        repackExpiresAt\n        canopySize\n        packValue\n      }\n    }\n  }\n"]))),C=Object(m.a)(a||(a=s()(["\n  mutation UpdateDropzoneRig(\n    $id: Int!\n    $isPublic: Boolean,\n  ) {\n    updateRig(\n      input: {\n        id: $id,\n        attributes: {\n          isPublic: $isPublic\n        }\n      }\n    ) {\n      errors\n      fieldErrors {\n        field\n        message\n      }\n      rig {\n        id\n        make\n        model\n        serial\n        isPublic\n        canopySize\n        repackExpiresAt\n        packValue\n        maintainedAt\n        rigType\n\n        dropzone {\n          id\n          rigs {\n            id\n            make\n            model\n            isPublic\n            serial\n            canopySize\n            repackExpiresAt\n            packValue\n            maintainedAt\n          }\n        }\n      }\n    }\n  }\n"])));function P(){var e,n,r=Object(k.c)((function(e){return e.global})),t=Object(k.c)((function(e){return e.forms.rig})),a=Object(d.useQuery)(w,{variables:{dropzoneId:Number(r.currentDropzoneId)}}),i=a.data,l=a.loading,s=a.refetch,c=Object(k.b)(),m=Object(p.useIsFocused)(),g=Object(d.useMutation)(C),P=o()(g,2),T=P[0],$=P[1],A=Object(S.a)(E.a.CreateDropzoneRig);return f.useEffect((function(){m&&s()}),[m]),f.createElement(O.a,{style:I.container,contentContainerStyle:[I.content,{backgroundColor:"white"}],refreshControl:f.createElement(b.a,{refreshing:l,onRefresh:function(){return s()}})},f.createElement(y.a,{visible:l||$.loading,color:r.theme.colors.accent}),f.createElement(h.a,null,f.createElement(h.a.Header,null,f.createElement(h.a.Title,null,"Container"),f.createElement(h.a.Title,{numeric:!0},"Repack due"),f.createElement(h.a.Title,{numeric:!0},"Canopy size"),f.createElement(h.a.Title,{numeric:!0},"Type"),f.createElement(h.a.Title,{numeric:!0},"Public")),null==i||null==(e=i.dropzone)||null==(n=e.rigs)?void 0:n.map((function(e){return f.createElement(h.a.Row,{key:"rig-"+e.id},f.createElement(h.a.Cell,{onPress:function(){c(k.a.forms.rig.setOpen(e))}},[null==e?void 0:e.make,null==e?void 0:e.model,"#"+(null==e?void 0:e.serial)].join(" ")),f.createElement(h.a.Cell,{numeric:!0},null!=e&&e.repackExpiresAt?Object(x.a)(1e3*e.repackExpiresAt,"yyyy/MM/dd"):"-"),f.createElement(h.a.Cell,{numeric:!0},""+(null==e?void 0:e.canopySize)),f.createElement(h.a.Cell,{numeric:!0},e.rigType),f.createElement(h.a.Cell,{numeric:!0},f.createElement(j.c,{onValueChange:function(){var n,r,t,a;return u.a.async((function(i){for(;;)switch(i.prev=i.next){case 0:return i.next=2,u.a.awrap(T({variables:{id:Number(e.id),isPublic:!e.isPublic}}));case 2:t=i.sent,null!=(a=t.data)&&null!=(n=a.updateRig)&&null!=(r=n.errors)&&r.length&&c(k.a.notifications.showSnackbar({message:null==a?void 0:a.updateRig.errors[0],variant:"error"}));case 5:case"end":return i.stop()}}),null,null,null,Promise)},value:!!e.isPublic})))}))),f.createElement(z.a,{onClose:function(){return c(k.a.forms.rig.setOpen(!1))},onSuccess:function(){c(k.a.forms.rig.setOpen(!1)),s()},dropzoneId:Number(r.currentDropzoneId),open:t.open}),f.createElement(v.a,{visible:A,style:I.fab,small:!0,icon:"plus",onPress:function(){return c(k.a.forms.rig.setOpen(!0))},label:"New rig"}))}var I=g.a.create({container:{flex:1,display:"flex"},content:{flexGrow:1},fab:{position:"absolute",margin:16,right:0,bottom:0},empty:{flex:1,alignItems:"center",justifyContent:"center",width:"100%",height:"100%"}})}}]);
//# sourceMappingURL=10.794f2264.chunk.js.map