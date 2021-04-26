(this.webpackJsonp=this.webpackJsonp||[]).push([[26],{404:function(e,n,r){"use strict";r.d(n,"a",(function(){return f})),r.d(n,"b",(function(){return b}));var t=r(27),a=r.n(t),l=r(13),o=r.n(l),i=r(0),s=r(59),c=r(5),d=r(197),u=r(200);function m(e,n){var r=Object(u.a)(),t=e[r];return t||d.a[r][n]}function f(e){var n=e.style,r=e.lightColor,t=e.darkColor,l=o()(e,["style","lightColor","darkColor"]),c=m({light:r,dark:t},"text");return i.createElement(s.a,a()({style:[{color:c},n]},l))}function b(e){var n=e.style,r=e.lightColor,t=e.darkColor,l=o()(e,["style","lightColor","darkColor"]),s=m({light:r,dark:t},"background");return i.createElement(c.a,a()({style:[{backgroundColor:s},n]},l))}},408:function(e,n,r){"use strict";r.d(n,"a",(function(){return c}));var t=r(0),a=r.n(t),l=r(89),o=r(4),i=r(409),s=r(60);function c(e){var n=Object(i.a)().height,r=Object(s.h)((function(e){return e.global})).theme;return a.a.createElement(l.a,{style:[d.container,{backgroundColor:r.colors.surface,height:n-112},e.style],contentContainerStyle:[d.content,e.contentContainerStyle]},e.children)}var d=o.a.create({container:{flex:1},content:{paddingHorizontal:16,alignItems:"flex-start",flexGrow:1,paddingBottom:50}})},426:function(e,n,r){"use strict";r.d(n,"a",(function(){return l}));var t=r(103),a=r(205),l=t.a.actions;a.a},458:function(e,n,r){"use strict";r.d(n,"a",(function(){return D}));var t,a=r(6),l=r.n(a),o=r(405),i=r.n(o),s=r(10),c=r.n(s),d=r(0),u=r.n(d),m=r(4),f=r(413),b=r(429),p=r(203),y=r(411),g=r(194),h=r(428),v=r(412),E=r(419),C=r(416),O=r(482),S=r(120),P=r(481),j=r(60),k=r(471),w=r.n(k),z=r(404),F=r(163).a.actions,x=Object(S.gql)(t||(t=i()(["\n  query QueryFederations {\n    federations {\n      id\n      name\n    }\n  }\n"])));function D(){var e,n,r,t,a=Object(j.h)((function(e){return e})),o=a.dropzoneForm,i=a.global,s=Object(j.g)(),m=Object(S.useQuery)(x),k=m.data,D=(m.loading,Object(d.useState)(!1)),$=l()(D,2),B=$[0],N=$[1],_=Object(d.useState)(null),q=l()(_,2),J=q[0],Q=q[1];Object(d.useEffect)((function(){var e,n;null==k||null==(e=k.federations)||!e.length||null!=(n=o.fields.federation)&&n.value||s(F.setField(["federation",k.federations[0]]))}),[JSON.stringify(null==k?void 0:k.federations)]);var U=Object(d.useCallback)((function(){var e;return c.a.async((function(n){for(;;)switch(n.prev=n.next){case 0:return n.prev=0,n.next=3,c.a.awrap(Object(O.a)({multiple:!1,type:"image"}));case 3:e=n.sent,s(F.setField(["banner",e.uri])),n.next=10;break;case 7:n.prev=7,n.t0=n.catch(0),console.log(n.t0);case 10:case"end":return n.stop()}}),null,null,[[0,7]],Promise)}),[s]);return u.a.createElement(u.a.Fragment,null,u.a.createElement(f.a,null,u.a.createElement(b.a,{visible:!!J,onDismiss:function(){return Q(null)}},u.a.createElement(b.a.Title,null,"Pick a ","primary"===J?"primary color":"secondary color"),u.a.createElement(b.a.Content,{style:{padding:20,height:400}},u.a.createElement(P.a,{onColorSelected:function(e){s("primary"===J?F.setField(["primaryColor",e]):F.setField(["secondaryColor",e]))},style:{flex:1},sliderComponent:w.a,defaultColor:("primary"===J?o.fields.primaryColor.value:o.fields.secondaryColor.value)||void 0,hideSliders:!0})),u.a.createElement(b.a.Actions,null,u.a.createElement(p.a,{onPress:function(){return Q(null)}},"Cancel"),u.a.createElement(p.a,{disabled:"primary"===J&&!o.fields.primaryColor.value||"secondary"===J&&!o.fields.secondaryColor.value,onPress:function(){console.log({current:i.theme.colors.accent,next:o.fields.secondaryColor.value}),s("primary"===J?j.b.setPrimaryColor(o.fields.primaryColor.value):j.b.setAccentColor(o.fields.secondaryColor.value)),Q(null)}},"Save")))),u.a.createElement(y.a,{style:{width:"100%",maxHeight:300,marginVertical:16}},u.a.createElement(y.a.Cover,{source:{uri:o.fields.banner.value||"https://picsum.photos/700"},resizeMode:"cover"}),u.a.createElement(y.a.Actions,{style:{justifyContent:"flex-end"}},u.a.createElement(p.a,{onPress:U},"Upload"))),u.a.createElement(y.a,{style:{width:"100%",marginVertical:16,paddingHorizontal:16}},u.a.createElement(g.a.Subheader,{style:I.subheader},"Dropzone"),u.a.createElement(h.a,{style:I.field,mode:"outlined",label:"Name",error:!!o.fields.name.error,value:o.fields.name.value||"",onChangeText:function(e){return s(F.setField(["name",e]))}}),u.a.createElement(v.a,{type:"error"},o.fields.name.error||""),u.a.createElement(g.a.Subheader,{style:I.subheader},"Federation"),u.a.createElement(E.a,{onDismiss:function(){return N(!1)},visible:B,anchor:u.a.createElement(E.a.Item,{onPress:function(){return N(!0)},title:(null==(e=o.fields)||null==(n=e.federation)||null==(r=n.value)?void 0:r.name)||"",icon:"parachute"})},null==k||null==(t=k.federations)?void 0:t.map((function(e){return u.a.createElement(E.a.Item,{title:e.name,onPress:function(){s(F.setField(["federation",e])),N(!1)}})}))),u.a.createElement(v.a,{type:"error"},o.fields.federation.error||""),u.a.createElement(g.a.Subheader,{style:I.subheader},"Branding"),u.a.createElement(g.a.Item,{title:"Primary color",onPress:function(){return Q("primary")},left:function(){return u.a.createElement(z.b,{style:{width:24,height:24,backgroundColor:i.theme.colors.primary}})}}),u.a.createElement(g.a.Item,{title:"Secondary color",onPress:function(){return Q("secondary")},left:function(){return u.a.createElement(z.b,{style:{width:24,height:24,backgroundColor:i.theme.colors.accent}})}}),u.a.createElement(g.a.Item,{title:"Use credit system",description:"Users will be charged credits when a load is marked as landed and can't manifest with insufficient funds.",onPress:function(){return s(F.setField(["isCreditSystemEnabled",!o.fields.isCreditSystemEnabled.value]))},left:function(){return u.a.createElement(C.a,{onPress:function(){return s(F.setField(["isCreditSystemEnabled",!o.fields.isCreditSystemEnabled.value]))},status:o.fields.isCreditSystemEnabled.value?"checked":"unchecked"})}}),u.a.createElement(g.a.Item,{title:"Public",description:"Your dropzone will not be available in the app if this is disabled",onPress:function(){return s(F.setField(["isPublic",!o.fields.isPublic.value]))},left:function(){return u.a.createElement(C.a,{onPress:function(){return s(F.setField(["isPublic",!o.fields.isPublic.value]))},status:o.fields.isPublic.value?"checked":"unchecked"})}})))}var I=m.a.create({fields:{flexGrow:1,display:"flex",width:"100%"},field:{marginBottom:8,width:"100%"},subheader:{paddingLeft:0}})},517:function(e,n,r){"use strict";r.r(n),r.d(n,"default",(function(){return I}));var t,a,l=r(7),o=r.n(l),i=r(6),s=r.n(i),c=r(405),d=r.n(c),u=r(10),m=r.n(u),f=r(0),b=r(4),p=r(390),y=r(203),g=r(120),h=r(60),v=r(404),E=r(426),C=r(161),O=r(163),S=r(458),P=r(73),j=r(408);function k(e,n){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var t=Object.getOwnPropertySymbols(e);n&&(t=t.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),r.push.apply(r,t)}return r}function w(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{};n%2?k(Object(r),!0).forEach((function(n){o()(e,n,r[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):k(Object(r)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(r,n))}))}return e}var z=O.a.actions,F=C.a.actions,x=Object(g.gql)(t||(t=d()(["\n  query QueryDropzoneDetails($dropzoneId: Int!) {\n    dropzone(id: $dropzoneId) {\n      id\n      name\n      primaryColor,\n      secondaryColor,\n      planes {\n        id\n        name\n        registration\n      }\n      ticketTypes {\n        id\n        name\n      }\n    }\n  }\n"]))),D=Object(g.gql)(a||(a=d()(["\n  mutation UpdateDropzone(\n    $id: Int!,\n    $name: String!,\n    $banner: String,\n    $federationId: Int!\n    $primaryColor: String\n    $secondaryColor: String\n    $isCreditSystemEnabled: Boolean,\n    $isPublic: Boolean\n  ){\n    updateDropzone(input: {\n      id: $id\n      attributes: {\n        name: $name,\n        banner: $banner,\n        federationId: $federationId\n        primaryColor: $primaryColor\n        secondaryColor: $secondaryColor\n        isCreditSystemEnabled: $isCreditSystemEnabled\n        isPublic: $isPublic\n      }\n    }) {\n      dropzone {\n        id\n        name\n        banner\n        primaryColor\n        secondaryColor,\n        isCreditSystemEnabled\n\n        planes {\n          id\n          name\n        }\n\n        federation {\n          id\n          name\n        }\n      }\n    }\n  }\n"])));function I(){var e,n=Object(h.h)((function(e){return e.dropzoneForm})),r=Object(h.h)((function(e){return e.global})),t=Object(h.g)(),a=Object(P.useRoute)().params.dropzone,l=Object(P.useNavigation)(),o=Object(g.useQuery)(x,{variables:{dropzoneId:Number(a.id)}}),i=o.data,c=o.loading;f.useEffect((function(){var e;null!=i&&null!=(e=i.dropzone)&&e.id&&t(z.setOriginal(i.dropzone))}),[null==i||null==(e=i.dropzone)?void 0:e.id]);var d=Object(g.useMutation)(D),u=s()(d,2),b=u[0],C=u[1],O=f.useCallback((function(){var e,o,i,s,c,d,u,f,p,y,g,v,C,O,S,P,j,k,x,D,I,$,B,N,_,q,J,Q;return m.a.async((function(U){for(;;)switch(U.prev=U.next){case 0:if(i=!1,s=n.fields,c=s.name,d=s.banner,u=s.federation,f=s.primaryColor,p=s.secondaryColor,y=s.isCreditSystemEnabled,g=s.isPublic,(null==(e=c.value)||!e.length||(null==(o=c.value)?void 0:o.length)<3)&&(i=!0,t(z.setFieldError(["name","Name is too short"]))),i){U.next=19;break}return U.prev=4,U.next=7,m.a.awrap(b({variables:{id:Number(null==a?void 0:a.id),name:c.value,banner:d.value||null,primaryColor:f.value,secondaryColor:p.value,federationId:Number(null==u||null==(v=u.value)?void 0:v.id),isCreditSystemEnabled:!!y,isPublic:!!g}}));case 7:if(null==($=U.sent)||null==(C=$.data)||null==(O=C.updateDropzone)||null==(S=O.fieldErrors)||S.map((function(e){var n=e.field,r=e.message;switch(n){case"federation":case"federation_id":return t(z.setFieldError(["federation",r]));case"banner":return t(z.setFieldError(["banner",r]));case"primary_color":return t(z.setFieldError(["primaryColor",r]));case"secondary_color":return t(z.setFieldError(["secondaryColor",r]));case"is_credit_system_enabled":return t(z.setFieldError(["isCreditSystemEnabled",r]));case"name":return t(z.setFieldError(["name",r]));case"is_public":return t(z.setFieldError(["isPublic",r]))}})),null==$||null==(P=$.data)||null==(j=P.updateDropzone)||null==(k=j.errors)||!k.length){U.next=13;break}return U.abrupt("return",t(h.f.showSnackbar({message:null==$||null==(B=$.data)||null==(N=B.updateDropzone)?void 0:N.errors[0],variant:"error"})));case 13:null!=$&&null!=(x=$.data)&&null!=(D=x.updateDropzone)&&null!=(I=D.fieldErrors)&&I.length||null!=(_=$.data)&&null!=(q=_.updateDropzone)&&q.dropzone&&(t(F.setDropzone(w(w({},r.currentDropzone||{}),null==$||null==(J=$.data)||null==(Q=J.updateDropzone)?void 0:Q.dropzone))),t(E.a.showSnackbar({message:"Saved",variant:"success"})),l.goBack());case 14:U.next=19;break;case 16:U.prev=16,U.t0=U.catch(4),t(E.a.showSnackbar({message:U.t0.message,variant:"error"}));case 19:case"end":return U.stop()}}),null,null,[[4,16]],Promise)}),[JSON.stringify(n.fields),t,b]);return f.createElement(f.Fragment,null,f.createElement(p.a,{indeterminate:!0,color:r.theme.colors.accent,visible:c}),f.createElement(j.a,{contentContainerStyle:$.content},f.createElement(S.a,null),f.createElement(v.b,{style:$.fields},f.createElement(y.a,{mode:"contained",disabled:C.loading,onPress:O,loading:C.loading},"Save"))))}var $=b.a.create({container:{flex:1,backgroundColor:"white",display:"flex"},content:{display:"flex",flexGrow:1,alignItems:"center",padding:48},title:{fontSize:20,fontWeight:"bold"},separator:{marginVertical:30,height:1,width:"80%"},fields:{width:"70%",marginBottom:16},field:{marginBottom:8}})}}]);
//# sourceMappingURL=26.1287426d.chunk.js.map