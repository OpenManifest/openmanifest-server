(this.webpackJsonp=this.webpackJsonp||[]).push([[8],{462:function(e,n,t){"use strict";var r=t(11),a=t.n(r),o=t(0),l=t(1),i=t(2),s=t(44),c=t(60);function u(){return(u=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var d=function(e){var n=e.children,t=e.style,r=e.numeric,l=a()(e,["children","style","numeric"]);return o.createElement(c.a,u({},l,{style:[m.container,r&&m.right,t]}),o.createElement(s.a,{numberOfLines:1},n))};d.displayName="DataTable.Cell";var m=l.a.create({container:{flex:1,flexDirection:"row",alignItems:"center"},right:{justifyContent:"flex-end"}}),f=d,p=t(20),g=t.n(p),h=t(26),b=t(19);function v(){return(v=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var y=function(e){var n=e.children,t=e.style,r=e.theme,l=a()(e,["children","style","theme"]),s=g()(r.dark?h.h:h.a).alpha(.12).rgb().string();return o.createElement(i.a,v({},l,{style:[E.header,{borderBottomColor:s},t]}),n)};y.displayName="DataTable.Header";var E=l.a.create({header:{flexDirection:"row",height:48,paddingHorizontal:16,borderBottomWidth:2*l.a.hairlineWidth}}),x=Object(b.c)(y),O=t(10),S=t(72),j=t(27),w=t(82);function P(){return(P=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var C=function(e){var n=e.numeric,t=e.children,r=e.onPress,l=e.sortDirection,c=e.theme,u=e.style,d=e.numberOfLines,m=void 0===d?1:d,f=a()(e,["numeric","children","onPress","sortDirection","theme","style","numberOfLines"]),p=o.useRef(new O.a.Value("ascending"===l?0:1)).current;o.useEffect((function(){O.a.timing(p,{toValue:"ascending"===l?0:1,duration:150,useNativeDriver:!0}).start()}),[l,p]);var h=g()(c.colors.text).alpha(.6).rgb().string(),b=p.interpolate({inputRange:[0,1],outputRange:["0deg","180deg"]}),v=l?o.createElement(O.a.View,{style:[$.icon,{transform:[{rotate:b}]}]},o.createElement(w.b,{name:"arrow-up",size:16,color:c.colors.text,direction:j.a.isRTL?"rtl":"ltr"})):null;return o.createElement(S.a,P({disabled:!r,onPress:r},f),o.createElement(i.a,{style:[$.container,n&&$.right,u]},v,o.createElement(s.a,{style:[$.cell,l?$.sorted:{color:h}],numberOfLines:m},t)))};C.displayName="DataTable.Title";var $=l.a.create({container:{flex:1,flexDirection:"row",alignContent:"center",paddingVertical:12},right:{justifyContent:"flex-end"},cell:{height:24,lineHeight:24,fontSize:12,fontWeight:"500",alignItems:"center"},sorted:{marginLeft:8},icon:{height:24,justifyContent:"center"}}),z=Object(b.c)(C),H=t(160);function I(){return(I=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var R=function(e){var n=e.label,t=e.page,r=e.numberOfPages,l=e.onPageChange,c=e.style,u=e.theme,d=a()(e,["label","page","numberOfPages","onPageChange","style","theme"]),m=g()(u.colors.text).alpha(.6).rgb().string();return o.createElement(i.a,I({},d,{style:[M.container,c]}),o.createElement(s.a,{style:[M.label,{color:m}],numberOfLines:1},n),o.createElement(H.a,{icon:function(e){var n=e.size,t=e.color;return o.createElement(w.b,{name:"chevron-left",color:t,size:n,direction:j.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===t,onPress:function(){return l(t-1)}}),o.createElement(H.a,{icon:function(e){var n=e.size,t=e.color;return o.createElement(w.b,{name:"chevron-right",color:t,size:n,direction:j.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===r||t===r-1,onPress:function(){return l(t+1)}}))};R.displayName="DataTable.Pagination";var M=l.a.create({container:{justifyContent:"flex-end",flexDirection:"row",alignItems:"center",paddingLeft:16},label:{fontSize:12,marginRight:44}}),T=Object(b.c)(R);function k(){return(k=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var D=l.a.create({container:{borderStyle:"solid",borderBottomWidth:l.a.hairlineWidth,minHeight:48,paddingHorizontal:16},content:{flex:1,flexDirection:"row"}}),N=Object(b.c)((function(e){var n=e.onPress,t=e.style,r=e.theme,l=e.children,s=e.pointerEvents,u=a()(e,["onPress","style","theme","children","pointerEvents"]),d=g()(r.dark?h.h:h.a).alpha(.12).rgb().string();return o.createElement(c.a,k({},u,{onPress:n,style:[D.container,{borderBottomColor:d},t]}),o.createElement(i.a,{style:D.content,pointerEvents:s},l))}));function F(){return(F=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e}).apply(this,arguments)}var L=function(e){var n=e.children,t=e.style,r=a()(e,["children","style"]);return o.createElement(i.a,F({},r,{style:[A.container,t]}),n)};L.Header=x,L.Title=z,L.Row=N,L.Cell=f,L.Pagination=T;var A=l.a.create({container:{width:"100%"}});n.a=L},617:function(e,n,t){"use strict";t.d(n,"a",(function(){return d}));var r=t(0),a=t(1),o=t(148),l=t(253),i=t(395),s=t(388),c=t(202),u=t(7);function d(e){var n=e.buttonLabel,t=e.buttonAction,a=e.title,d=e.loading,m=e.children,f=Object(u.c)((function(e){return e.global}));return r.createElement(l.a,null,r.createElement(i.a,{visible:!!e.open,dismissable:!1,style:{maxWidth:500,alignSelf:"center"}},r.createElement(s.a,{indeterminate:!0,visible:d,color:f.theme.colors.accent}),r.createElement(i.a.Title,null,a),r.createElement(i.a.Content,{pointerEvents:"box-none"},r.createElement(i.a.ScrollArea,null,r.createElement(o.b,null,m))),r.createElement(i.a.Actions,{style:{justifyContent:"flex-end"}},r.createElement(c.a,{onPress:function(){e.onClose()}},"Cancel"),r.createElement(c.a,{onPress:t},n))))}a.a.create({button:{width:"100%",borderRadius:16,padding:5},contentContainer:{paddingHorizontal:16,paddingBottom:32},sheet:{elevation:3,backgroundColor:"white",flexGrow:1,height:"100%",display:"flex",flexDirection:"column",justifyContent:"center"},sheetHeader:{elevation:2,borderTopLeftRadius:20,borderTopRightRadius:20,height:40,shadowColor:"#000",shadowOffset:{width:0,height:-4},backgroundColor:"white",shadowOpacity:.22,shadowRadius:2.22}})},623:function(e,n,t){"use strict";t.d(n,"a",(function(){return i}));var r=t(0),a=t(10),o=t(148),l=t(333);function i(e){var n=e.children,t=e.rightAction,i=e.disabled,s=r.useRef();return r.createElement(l.a,{ref:s,enabled:!i,renderRightActions:function(e,n){var l=n.interpolate({inputRange:[-100,0],outputRange:[1,0]}),i=n.interpolate({inputRange:[-150,0],outputRange:[0,10]});return r.createElement(o.d,{onPress:function(){var e;null==t||t.onPress(),null==s||null==(e=s.current)||e.close()}},r.createElement(a.a.View,{style:{flexGrow:1,backgroundColor:null==t?void 0:t.backgroundColor,justifyContent:"center",height:"100%",width:75,transform:[{translateX:i}]}},r.createElement(a.a.Text,{style:{color:"white",paddingHorizontal:10,fontWeight:"600",transform:[{scale:l}]}},null==t?void 0:t.label)))},useNativeAnimations:!0},n)}},624:function(e,n,t){"use strict";t.d(n,"a",(function(){return s}));var r=t(0),a=t(1),o=t(284),l=t(282),i=t(7);function s(){var e,n,t,a,s=Object(i.c)((function(e){return e.forms.plane})),u=Object(i.b)();return r.createElement(r.Fragment,null,r.createElement(o.a,{style:c.field,mode:"outlined",label:"Name",error:!!s.fields.name.error,value:s.fields.name.value,onChangeText:function(e){return u(i.a.forms.plane.setField(["name",e]))}}),r.createElement(l.a,{type:s.fields.name.error?"error":"info"},s.fields.name.error||""),r.createElement(o.a,{style:c.field,mode:"outlined",label:"Registration",error:!!s.fields.registration.error,value:s.fields.registration.value,onChangeText:function(e){return u(i.a.forms.plane.setField(["registration",e]))}}),r.createElement(l.a,{type:s.fields.registration.error?"error":"info"},s.fields.registration.error||""),r.createElement(o.a,{style:c.field,mode:"outlined",label:"hours",error:!!s.fields.hours.error,value:null==(e=s.fields.hours)||null==(n=e.value)?void 0:n.toString(),placeholder:"Optional",onChangeText:function(e){return u(i.a.forms.plane.setField(["hours",Number(e)]))}}),r.createElement(l.a,{type:s.fields.hours.error?"error":"info"},s.fields.hours.error||""),r.createElement(o.a,{style:c.field,mode:"outlined",label:"Min slots",error:!!s.fields.minSlots.error,value:null==(t=s.fields.minSlots.value)?void 0:t.toString(),keyboardType:"number-pad",onChangeText:function(e){return u(i.a.forms.plane.setField(["minSlots",Number(e)]))}}),r.createElement(l.a,{type:s.fields.minSlots.error?"error":"info"},s.fields.minSlots.error||"Minimum tickets required to send it"),r.createElement(o.a,{style:c.field,mode:"outlined",label:"Max slots",error:!!s.fields.maxSlots.error,value:null==(a=s.fields.maxSlots)?void 0:a.value.toString(),keyboardType:"number-pad",onChangeText:function(e){return u(i.a.forms.plane.setField(["maxSlots",Number(e)]))}}),r.createElement(l.a,{type:s.fields.maxSlots.error?"error":"info"},s.fields.maxSlots.error||"Maximum amount of jumpers who can be manifested on one load"))}var c=a.a.create({fields:{width:"100%",flex:1},field:{width:"100%",marginBottom:8}})},784:function(e,n,t){"use strict";t.r(n),t.d(n,"default",(function(){return A}));var r,a,o=t(12),l=t.n(o),i=t(36),s=t.n(i),c=t(8),u=t.n(c),d=t(47),m=t(37),f=t(0),p=t(1),g=t(224),h=t(388),b=t(462),v=t(396),y=t(97),E=t(56),x=t(7),O=t(330),S=t(158),j=t(4),w=t.n(j),P=t(624),C=t(617),$=t(327);function z(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function H(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?z(Object(t),!0).forEach((function(n){w()(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):z(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}var I=Object(d.gql)(r||(r=s()(["\n  mutation UpdatePlane(\n    $id: Int!,\n    $name: String!,\n    $registration: String!,\n    $minSlots: Int!\n    $maxSlots: Int!\n    $hours: Int\n    $nextMaintenanceHours: Int\n  ){\n    updatePlane(input: {\n      id: $id\n      attributes: {\n        name: $name,\n        registration: $registration,\n        minSlots: $minSlots\n        maxSlots: $maxSlots\n        hours: $hours\n        nextMaintenanceHours: $nextMaintenanceHours\n      }\n    }) {\n      plane {\n        id\n        name\n        registration\n        minSlots\n        maxSlots\n        hours\n        nextMaintenanceHours\n\n        dropzone {\n          id\n          name\n          planes {\n            id\n            name\n            registration\n            minSlots\n            maxSlots\n            hours\n            nextMaintenanceHours\n          }\n        }\n      }\n      fieldErrors {\n        field\n        message\n      }\n      errors\n    }\n  }\n"]))),R=Object(d.gql)(a||(a=s()(["\n  mutation CreatePlane(\n    $name: String!,\n    $registration: String!,\n    $dropzoneId: Int!\n    $minSlots: Int!\n    $maxSlots: Int!\n    $hours: Int\n    $nextMaintenanceHours: Int\n  ){\n    createPlane(input: {\n      attributes: {\n        name: $name,\n        registration: $registration,\n        dropzoneId: $dropzoneId\n        minSlots: $minSlots\n        maxSlots: $maxSlots\n        hours: $hours\n        nextMaintenanceHours: $nextMaintenanceHours\n      }\n    }) {\n      plane {\n        ...plane,\n\n        dropzone {\n          id\n          planes {\n            ...plane\n          }\n        }\n      }\n      fieldErrors {\n        field\n        message\n      }\n      errors\n    }\n  }\n  fragment plane on Plane {\n    id\n    name\n    registration\n    minSlots\n    maxSlots\n    hours\n    nextMaintenanceHours\n\n    dropzone {\n      id\n      name\n      planes {\n        id\n        name\n        registration\n        minSlots\n        maxSlots\n        hours\n        nextMaintenanceHours\n      }\n    }\n  }\n"])));function M(e){var n,t=e.open,r=e.onClose,a=Object($.a)(),o=Object(x.c)((function(e){return e.forms.plane})),i=Object(x.b)(),s=Object(d.useMutation)(R),c=l()(s,2),m=c[0],p=c[1],g=Object(d.useMutation)(I),h=l()(g,2),b=h[0],v=h[1],y=f.useCallback((function(){var e=!1;return o.fields.name.value.length<3&&(e=!0,i(x.a.forms.plane.setFieldError(["name","Name is too short"]))),o.fields.registration.value.length<3&&(e=!0,i(x.a.forms.plane.setFieldError(["registration","Registration is too short"]))),o.fields.maxSlots.value||(e=!0,i(x.a.forms.plane.setFieldError(["maxSlots","Max slots must be specified"]))),!e}),[JSON.stringify(o.fields),i]),E=f.useCallback((function(){var e,n,t,l,s,c,d,f,p,g,h,v,E,O,S,j,w,P,C;return u.a.async((function($){for(;;)switch($.prev=$.next){case 0:if(n=o.fields,t=n.name,l=n.registration,s=n.maxSlots,c=n.minSlots,d=n.hours,f=n.nextMaintenanceHours,p=null!=(e=o.original)&&e.id?b:m,!y()){$.next=18;break}return $.prev=3,$.next=6,u.a.awrap(p({variables:H(H({},null!=(g=o.original)&&g.id?{id:Number(o.original.id)}:{dropzoneId:Number(null==a||null==(h=a.dropzone)?void 0:h.id)}),{},{name:t.value,registration:l.value,minSlots:c.value,maxSlots:s.value,hours:d.value,nextMaintenanceHours:f.value})}));case 6:if(w=$.sent,null==(P=null!=(v=o.original)&&v.id?null==w||null==(E=w.data)?void 0:E.updatePlane:null==w||null==(O=w.data)?void 0:O.createPlane)||null==(S=P.fieldErrors)||!S.length){$.next=11;break}return P.fieldErrors.forEach((function(e){var n=e.field,t=e.message;switch(n){case"max_slots":return i(x.a.forms.plane.setFieldError(["maxSlots",t]));case"name":return i(x.a.forms.plane.setFieldError(["name",t]));case"min_slots":return i(x.a.forms.plane.setFieldError(["minSlots",t]));case"hours":return i(x.a.forms.plane.setFieldError(["hours",t]));case"next_maintenance_hours":return i(x.a.forms.plane.setFieldError(["nextMaintenanceHours",t]));case"registration":return i(x.a.forms.plane.setFieldError(["registration",t]))}})),$.abrupt("return");case 11:null!=(j=P.errors)&&j.length&&P.errors.forEach((function(e){return i(x.a.notifications.showSnackbar({message:e,variant:"error"}))})),null!=P&&P.plane&&(C=null==P?void 0:P.plane,i(x.a.notifications.showSnackbar({message:"Added plane "+C.name,variant:"success"})),r(),i(x.a.forms.plane.reset())),$.next=18;break;case 15:$.prev=15,$.t0=$.catch(3),i(x.a.notifications.showSnackbar({message:$.t0.message,variant:"error"}));case 18:case"end":return $.stop()}}),null,null,[[3,15]],Promise)}),[JSON.stringify(o.fields),i,m]);return f.createElement(C.a,{title:null!=(n=o.original)&&n.id?"Edit aircraft":"New aircraft",open:t,snapPoints:[0,580],buttonLabel:"Save",buttonAction:E,loading:p.loading||v.loading,onClose:function(e){function n(){return e.apply(this,arguments)}return n.toString=function(){return e.toString()},n}((function(){r(),i(x.a.forms.plane.reset())}))},f.createElement(P.a,null))}var T,k,D=t(116),N=t(623),F=Object(m.a)(T||(T=s()(["\n  query QueryPlanes(\n    $dropzoneId: Int!\n  ) {\n    dropzone(id: $dropzoneId) {\n      id\n      planes {\n        id\n        name\n        registration\n        hours\n        minSlots\n        maxSlots\n        nextMaintenanceHours\n        createdAt\n      }\n    }\n  }\n"]))),L=Object(m.a)(k||(k=s()(["\nmutation DeletePlane($id: Int!) {\n  deletePlane(input: { id: $id }) {\n    errors\n    plane {\n      id\n      dropzone {\n        id\n        planes {\n          name\n          registration\n          hours\n          minSlots\n          maxSlots\n          nextMaintenanceHours\n          createdAt\n        }\n      }\n    }\n  }\n}\n"])));function A(){var e,n,t,r,a,o,i=Object(x.c)((function(e){return e.global})),s=Object(x.c)((function(e){return e.forms.plane})),c=Object(d.useQuery)(F,{variables:{dropzoneId:Number(i.currentDropzoneId)}}),m=c.data,p=c.loading,j=c.refetch,w=Object(d.useMutation)(L),P=l()(w,2),C=P[0],$=(P[1],Object(x.b)()),z=Object(E.useIsFocused)();f.useEffect((function(){z&&j()}),[z]);var H=Object(D.a)(y.a.DeletePlane),I=Object(D.a)(y.a.CreatePlane);return f.createElement(f.Fragment,null,f.createElement(S.a,{refreshControl:f.createElement(g.a,{refreshing:p,onRefresh:j})},f.createElement(h.a,{visible:p,color:i.theme.colors.accent}),null!=m&&null!=(e=m.dropzone)&&null!=(n=e.planes)&&n.length?null:f.createElement(O.a,{title:"No planes?",subtitle:"You need to have at least one plane to manifest loads"}),null!=m&&null!=(t=m.dropzone)&&null!=(r=t.planes)&&r.length?f.createElement(b.a,null,f.createElement(b.a.Header,null,f.createElement(b.a.Title,null,"Name"),f.createElement(b.a.Title,{numeric:!0},"Registration"),f.createElement(b.a.Title,{numeric:!0},"Slots")),null==m||null==(a=m.dropzone)||null==(o=a.planes)?void 0:o.map((function(e){return f.createElement(N.a,{disabled:!H,rightAction:{label:"Delete",backgroundColor:"red",onPress:function(){var n,t,r,a;return u.a.async((function(o){for(;;)switch(o.prev=o.next){case 0:return o.next=2,u.a.awrap(C({variables:{id:Number(e.id)}}));case 2:r=o.sent,null!=(a=r.data)&&null!=(n=a.deletePlane)&&null!=(t=n.errors)&&t.length&&$(x.a.notifications.showSnackbar({message:a.deletePlane.errors[0],variant:"error"}));case 5:case"end":return o.stop()}}),null,null,null,Promise)}}},f.createElement(b.a.Row,{pointerEvents:"none",onPress:function(){$(x.a.forms.plane.setOpen(e))}},f.createElement(b.a.Cell,null,e.name),f.createElement(b.a.Cell,{numeric:!0},e.registration),f.createElement(b.a.Cell,{numeric:!0},e.maxSlots)))}))):null,f.createElement(v.a,{style:W.fab,visible:I,small:!0,icon:"plus",onPress:function(){return $(x.a.forms.plane.setOpen(!0))},label:"New plane"})),f.createElement(M,{open:s.open,onClose:function(){return $(x.a.forms.plane.setOpen(!1))}}))}var W=p.a.create({content:{flexGrow:1},fab:{position:"absolute",margin:16,right:0,bottom:0},empty:{flex:1,alignItems:"center",justifyContent:"center",width:"100%",height:"100%"}})}}]);
//# sourceMappingURL=8.3b4305ae.chunk.js.map