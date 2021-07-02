(this.webpackJsonp=this.webpackJsonp||[]).push([[11],{578:function(e,n,r){"use strict";r.d(n,"a",(function(){return l}));var a=r(136),t=r(293),l=a.a.actions;t.a},579:function(e,n,r){"use strict";r.d(n,"a",(function(){return o}));var a=r(38),t=r(0),l=r(5);function o(e,n){var r=n.getPayload;return function(n){var o=n.variables,i=n.onError,s=Object(l.b)(),u=Object(a.useQuery)(e,{variables:o}),d=u.data,c=u.loading,m=u.previousData,f=u.refetch,p=u.error,v=t.useMemo((function(){return r(d)}),[JSON.stringify(d)]);return t.useEffect((function(){JSON.stringify(m),JSON.stringify(d);null!=p&&p.message&&(!1!==n.showSnackbarErrors&&s(l.a.notifications.showSnackbar({message:p.message,variant:"error"})),i&&p.message)}),[n.onError,null==p?void 0:p.message]),{loading:c,data:v,refetch:f}}}},608:function(e,n,r){"use strict";r.d(n,"a",(function(){return k}));var a,t=r(0),l=r(1),o=r(2),i=r(251),s=r(249),u=r(340),d=r(252),c=r(5),m=r(9),f=r.n(m),p=r(21),v=r(31),b=r.n(v),g=r(32),S=r(579),E=Object(g.a)(a||(a=b()(["\nquery QueryDropzoneUsers(\n  $dropzoneId: Int!\n  $permissions: [Permission!]\n) {\n  dropzone(id: $dropzoneId) {\n    id\n    name\n\n    dropzoneUsers(permissions: $permissions) {\n      edges {\n        node {\n          id\n          role {\n            id\n            name\n          }\n          user {\n            id\n            name\n          }\n        }\n      }\n    }\n  }\n}\n"]))),h=Object(S.a)(E,{getPayload:function(e){var n;return null==e||null==(n=e.dropzone)?void 0:n.dropzoneUsers}}),O=r(291);function I(e){var n,r=e.label,a=e.requiredPermissions,l=e.icon,o=(e.required,e.value),i=Object(c.c)((function(e){return e.global})).currentDropzoneId,s=Object(c.b)(),u=h({variables:{dropzoneId:Number(i),permissions:a},onError:function(e){return s(c.a.notifications.showSnackbar({message:e,variant:"error"}))}}),d=u.data;u.loading,u.refetch;return t.createElement(t.Fragment,null,t.createElement(p.b.Subheader,null,r),t.createElement(O.a,{autoSelectFirst:!0,icon:l||"account",items:(null==d||null==(n=d.edges)?void 0:n.map((function(e){return e.node})))||[],selected:[e.value].filter(Boolean),isSelected:function(e){return e.id===(null==o?void 0:o.id)},renderItemLabel:function(e){return null==e?void 0:e.user.name},isDisabled:function(){return!1},onChangeSelected:function(n){var r=f()(n,1)[0];return r?e.onSelect(r):null}}))}var y,x=r(24),F=r.n(x),j=r(38),z=r(84),w=Object(g.a)(y||(y=b()(["\n  query QuerySelectPlanes(\n    $dropzoneId: Int!\n  ) {\n    planes(dropzoneId: $dropzoneId) {\n      id\n      name\n      registration\n      hours\n      minSlots\n      maxSlots\n      nextMaintenanceHours\n      createdAt\n    }\n  }\n"])));function $(e){var n=Object(c.c)((function(e){return e.global})).currentDropzoneId,r=Object(j.useQuery)(w,{variables:{dropzoneId:n}}),a=r.data;r.loading,r.refetch;return t.createElement(t.Fragment,null,t.createElement(p.b.Subheader,null,"Aircraft"),t.createElement(O.a,{autoSelectFirst:!0,items:Object(z.uniqBy)(F()((null==a?void 0:a.planes)||[]),(function(e){return e.id}))||[],selected:[e.value].filter(Boolean),renderItemLabel:function(e){return null==e?void 0:e.name},isDisabled:function(e){return!1},onChangeSelected:function(n){var r=f()(n,1)[0];return r?e.onSelect(r):null}}))}function k(){var e,n,r=Object(c.c)((function(e){return e.forms.load})),a=Object(c.b)();Object(c.c)((function(e){return e.global}));return t.createElement(t.Fragment,null,t.createElement(i.a,{style:N.field,mode:"outlined",label:"Name",error:!!r.fields.name.error,placeholder:"Optional",value:r.fields.name.value||"",onChangeText:function(e){return a(c.a.forms.load.setField(["name",e]))}}),t.createElement(s.a,{type:r.fields.name.error?"error":"info"},r.fields.name.error||"e.g Starcrest load, Tandem load"),t.createElement(i.a,{style:N.field,mode:"outlined",label:"Slots",error:!!r.fields.maxSlots.error,value:null==(e=r.fields.maxSlots)||null==(n=e.value)?void 0:n.toString(),onChangeText:function(e){return a(c.a.forms.load.setField(["maxSlots",Number(e)]))}}),t.createElement(s.a,{type:r.fields.maxSlots.error?"error":"info"},r.fields.maxSlots.error||""),t.createElement(o.a,{style:{width:"100%"}},t.createElement($,{value:r.fields.plane.value,required:!0,onSelect:function(e){a(c.a.forms.load.setField(["plane",e])),a(c.a.forms.load.setField(["maxSlots",e.maxSlots]))}}),t.createElement(s.a,{type:r.fields.plane.error?"error":"info"},r.fields.plane.error||""),t.createElement(I,{label:"GCA",onSelect:function(e){return a(c.a.forms.load.setField(["gca",e]))},value:r.fields.gca.value||null,requiredPermissions:["actAsGCA"],required:!0}),t.createElement(s.a,{type:r.fields.gca.error?"error":"info"},r.fields.gca.error||""),t.createElement(I,{label:"Pilot",onSelect:function(e){return a(c.a.forms.load.setField(["pilot",e]))},value:r.fields.pilot.value||null,requiredPermissions:["actAsPilot"]}),t.createElement(s.a,{type:r.fields.pilot.error?"error":"info"},r.fields.pilot.error||""),t.createElement(u.a,{style:{marginVertical:8}}),t.createElement(d.a.Item,{label:"Allow public manifesting",status:r.fields.isOpen.value?"checked":"unchecked",onPress:function(){return a(c.a.forms.load.setField(["isOpen",!r.fields.isOpen.value]))}})))}var N=l.a.create({fields:{flex:1,width:"100%"},field:{marginBottom:8,width:"100%"}})},724:function(e,n,r){"use strict";r.r(n),r.d(n,"default",(function(){return F}));var a,t=r(9),l=r.n(t),o=r(31),i=r.n(o),s=r(4),u=r.n(s),d=r(0),c=r(1),m=r(173),f=r(38),p=r(5),v=r(47),b=r(134),g=r(578),S=r(275),E=r(608),h=r(191),O=r(396),I=r(290),y=S.a.actions,x=Object(f.gql)(a||(a=i()(["\n  mutation CreateLoad(\n    $name: String,\n    $pilotId: Int,\n    $gcaId: Int,\n    $maxSlots: Int!,\n    $planeId: Int,\n    $isOpen: Boolean,\n  ){\n    createLoad(input: {\n      attributes: {\n        name: $name,\n        pilotId: $pilotId,\n        gcaId: $gcaId,\n        maxSlots: $maxSlots,\n        planeId: $planeId,\n        isOpen: $isOpen,\n      }\n    }) {\n      load {\n        id\n        name\n        pilot {\n          id\n          user {\n            id \n            name\n          }\n        }\n        gca {\n          id\n          user {\n            id \n            name\n          }\n        }\n        maxSlots\n        isOpen\n      }\n      fieldErrors {\n        field,\n        message\n      }\n      errors\n    }\n  }\n"])));function F(){var e=Object(I.a)(),n=Object(p.c)((function(e){return e.forms.load})),r=Object(p.b)(),a=Object(v.useNavigation)(),t=Object(f.useMutation)(x),o=l()(t,2),i=o[0],s=o[1],c=d.useCallback((function(){var e=!1;return n.fields.maxSlots.value<1&&(e=!0,r(y.setFieldError(["maxSlots","Please specify amount of allowed jumpers"]))),n.fields.plane.value||(e=!0,r(y.setFieldError(["plane","What plane is flying this load?"]))),n.fields.gca.value||(e=!0,r(y.setFieldError(["gca","You must have a GCA for this load"]))),!e}),[JSON.stringify(n.fields),r]),S=d.useCallback((function(){var t,l,o,s,d,m,f,p,v,b,S,E,h,O,I,x,F,j,z,w,$,k,N,P,C,L,q,A;return u.a.async((function(B){for(;;)switch(B.prev=B.next){case 0:if(t=n.fields,l=t.name,o=t.gca,t.loadMaster,s=t.plane,d=t.maxSlots,m=t.pilot,f=t.isOpen,!c()){B.next=15;break}return B.prev=2,B.next=5,u.a.awrap(i({variables:{dropzoneId:Number(null==e||null==(p=e.dropzone)?void 0:p.id),name:l.value,maxSlots:d.value,planeId:null!=(v=s.value)&&v.id?Number(null==(b=s.value)?void 0:b.id):null,pilotId:null!=(S=m.value)&&S.id?Number(null==(E=s.value)?void 0:E.id):null,gcaId:null!=(h=o.value)&&null!=(O=h.user)&&O.id?Number(null==(I=o.value)||null==(x=I.user)?void 0:x.id):null,isOpen:!!f.value}}));case 5:if(C=B.sent,null==(F=C.data)||null==(j=F.createLoad)||null==(z=j.fieldErrors)||z.map((function(e){var n=e.field,a=e.message;switch(n){case"name":return r(y.setFieldError(["name",a]));case"maxSlots":return r(y.setFieldError(["maxSlots",a]));case"plane":return r(y.setFieldError(["plane",a]));case"gca":return r(y.setFieldError(["gca",a]));case"is_open":return r(y.setFieldError(["isOpen",a]));case"pilot":return r(y.setFieldError(["pilot",a]))}})),null==C||null==(w=C.data)||null==($=w.createLoad)||null==(k=$.errors)||!k.length){B.next=9;break}return B.abrupt("return",r(g.a.showSnackbar({message:C.data.createLoad.errors[0],variant:"error"})));case 9:null!=(N=C.data)&&null!=(P=N.createLoad)&&P.load&&(A=C.data.createLoad.load,r(g.a.showSnackbar({message:"Load "+A.name+" created",variant:"success"})),null!=(L=C.data)&&null!=(q=L.createLoad)&&q.fieldErrors||a.goBack()),B.next=15;break;case 12:B.prev=12,B.t0=B.catch(2),r(g.a.showSnackbar({message:B.t0.message,variant:"error"}));case 15:case"end":return B.stop()}}),null,null,[[2,12]],Promise)}),[JSON.stringify(n.fields),r,i]);return d.createElement(h.a,{contentContainerStyle:j.content},d.createElement(O.a,{name:"airplane-takeoff",size:100,color:"#999999",style:{alignSelf:"center",marginTop:32}}),d.createElement(E.a,null),d.createElement(b.b,{style:j.fields},d.createElement(m.a,{mode:"contained",style:j.button,disabled:s.loading,onPress:S,loading:s.loading},"Save")))}var j=c.a.create({content:{paddingHorizontal:48},button:{},title:{fontSize:20,fontWeight:"bold"},separator:{marginVertical:30,height:1,width:"80%"},fields:{marginVertical:16,width:"100%"},field:{marginBottom:8}})}}]);
//# sourceMappingURL=11.382fd9c0.chunk.js.map