(this.webpackJsonp=this.webpackJsonp||[]).push([[23],{772:function(e,n,r){"use strict";r.r(n),r.d(n,"default",(function(){return $}));var o,t,a=r(4),l=r.n(a),i=r(11),s=r.n(i),d=r(36),c=r.n(d),u=r(8),p=r.n(u),m=r(0),b=r(1),f=r(388),y=r(202),g=r(47),v=r(7),z=r(159),O=r(380),h=r(56),C=r(158);function E(e,n){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);n&&(o=o.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),r.push.apply(r,o)}return r}function S(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{};n%2?E(Object(r),!0).forEach((function(n){l()(e,n,r[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):E(Object(r)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(r,n))}))}return e}var j=Object(g.gql)(o||(o=c()(["\n  query QueryDropzoneDetails($dropzoneId: Int!) {\n    dropzone(id: $dropzoneId) {\n      id\n      name\n      primaryColor,\n      secondaryColor,\n      planes {\n        id\n        name\n        registration\n      }\n      ticketTypes {\n        id\n        name\n      }\n    }\n  }\n"]))),w=Object(g.gql)(t||(t=c()(["\n  mutation UpdateDropzone(\n    $id: Int!,\n    $name: String!,\n    $banner: String,\n    $federationId: Int!\n    $primaryColor: String\n    $secondaryColor: String\n    $isCreditSystemEnabled: Boolean,\n    $isPublic: Boolean\n  ){\n    updateDropzone(input: {\n      id: $id\n      attributes: {\n        name: $name,\n        banner: $banner,\n        federationId: $federationId\n        primaryColor: $primaryColor\n        secondaryColor: $secondaryColor\n        isCreditSystemEnabled: $isCreditSystemEnabled\n        isPublic: $isPublic\n      }\n    }) {\n      dropzone {\n        id\n        name\n        banner\n        primaryColor\n        secondaryColor,\n        isCreditSystemEnabled\n\n        planes {\n          id\n          name\n        }\n\n        federation {\n          id\n          name\n        }\n      }\n    }\n  }\n"])));function $(){var e,n=Object(v.c)((function(e){return e.forms.dropzone})),r=Object(v.c)((function(e){return e.global})),o=Object(v.b)(),t=Object(h.useRoute)().params.dropzone,a=Object(h.useNavigation)(),l=Object(g.useQuery)(j,{variables:{dropzoneId:Number(t.id)}}),i=l.data,d=l.loading;m.useEffect((function(){var e;null!=i&&null!=(e=i.dropzone)&&e.id&&o(v.a.forms.dropzone.setOpen(i.dropzone))}),[null==i||null==(e=i.dropzone)?void 0:e.id]);var c=Object(g.useMutation)(w),u=s()(c,2),b=u[0],E=u[1],$=m.useCallback((function(){var e,l,i,s,d,c,u,m,f,y,g,z,O,h,C,E,j,w,$,D,P,k,I,x,F,_,N,B;return p.a.async((function(q){for(;;)switch(q.prev=q.next){case 0:if(i=!1,s=n.fields,d=s.name,c=s.banner,u=s.federation,m=s.primaryColor,f=s.secondaryColor,y=s.isCreditSystemEnabled,g=s.isPublic,(null==(e=d.value)||!e.length||(null==(l=d.value)?void 0:l.length)<3)&&(i=!0,o(v.a.forms.dropzone.setFieldError(["name","Name is too short"]))),i){q.next=19;break}return q.prev=4,q.next=7,p.a.awrap(b({variables:{id:Number(null==t?void 0:t.id),name:d.value,banner:c.value||null,primaryColor:m.value,secondaryColor:f.value,federationId:Number(null==u||null==(z=u.value)?void 0:z.id),isCreditSystemEnabled:!!y,isPublic:!!g}}));case 7:if(null==(k=q.sent)||null==(O=k.data)||null==(h=O.updateDropzone)||null==(C=h.fieldErrors)||C.map((function(e){var n=e.field,r=e.message;switch(n){case"federation":case"federation_id":return o(v.a.forms.dropzone.setFieldError(["federation",r]));case"banner":return o(v.a.forms.dropzone.setFieldError(["banner",r]));case"primary_color":return o(v.a.forms.dropzone.setFieldError(["primaryColor",r]));case"secondary_color":return o(v.a.forms.dropzone.setFieldError(["secondaryColor",r]));case"is_credit_system_enabled":return o(v.a.forms.dropzone.setFieldError(["isCreditSystemEnabled",r]));case"name":return o(v.a.forms.dropzone.setFieldError(["name",r]));case"is_public":return o(v.a.forms.dropzone.setFieldError(["isPublic",r]))}})),null==k||null==(E=k.data)||null==(j=E.updateDropzone)||null==(w=j.errors)||!w.length){q.next=13;break}return q.abrupt("return",o(v.a.notifications.showSnackbar({message:null==k||null==(I=k.data)||null==(x=I.updateDropzone)?void 0:x.errors[0],variant:"error"})));case 13:null!=k&&null!=($=k.data)&&null!=(D=$.updateDropzone)&&null!=(P=D.fieldErrors)&&P.length||null!=(F=k.data)&&null!=(_=F.updateDropzone)&&_.dropzone&&(o(v.a.global.setDropzone(S(S({},r.currentDropzone||{}),null==k||null==(N=k.data)||null==(B=N.updateDropzone)?void 0:B.dropzone))),o(v.a.notifications.showSnackbar({message:"Saved",variant:"success"})),a.goBack());case 14:q.next=19;break;case 16:q.prev=16,q.t0=q.catch(4),o(v.a.notifications.showSnackbar({message:q.t0.message,variant:"error"}));case 19:case"end":return q.stop()}}),null,null,[[4,16]],Promise)}),[JSON.stringify(n.fields),o,b]);return m.createElement(m.Fragment,null,m.createElement(f.a,{indeterminate:!0,color:r.theme.colors.accent,visible:d}),m.createElement(C.a,{style:{backgroundColor:r.theme.colors.accent},contentContainerStyle:D.content},m.createElement(O.a,null),m.createElement(z.b,{style:D.fields},m.createElement(y.a,{mode:"contained",disabled:E.loading,onPress:$,loading:E.loading},"Save"))))}var D=b.a.create({container:{flex:1,backgroundColor:"white",display:"flex"},content:{display:"flex",flexGrow:1,alignSelf:"center",alignItems:"center",maxWidth:500,padding:48},title:{fontSize:20,fontWeight:"bold"},separator:{marginVertical:30,height:1,width:"80%"},fields:{width:"100%",marginBottom:16},field:{marginBottom:8}})}}]);
//# sourceMappingURL=23.9ec802bf.chunk.js.map