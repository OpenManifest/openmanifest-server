(this.webpackJsonp=this.webpackJsonp||[]).push([[43],{452:function(e,n,t){"use strict";var r,l=t(6),a=t.n(l),o=t(405),i=t.n(o),u=t(0),c=t.n(u),s=t(423),m=t(419),d=t(119),p=t(421),f=t(203),g=t(120),b=t(60),h=t(5),v=t(4),E=Object(g.gql)(r||(r=i()(["\n  query QueryDropzonesCompact {\n    dropzones {\n      edges {\n        node {\n          id\n          name\n        }\n      }\n    }\n  }\n"])));var y=v.a.create({warning:{flexDirection:"row",alignItems:"center",height:56,width:"100%",backgroundColor:"#ffbb33",justifyContent:"space-between",paddingHorizontal:32}});n.a=function(e){var n,t,r,l,o,i,v,P=e.navigation,z=e.previous,w=e.scene,S=Object(u.useState)(!1),j=a()(S,2),O=j[0],k=j[1],D=Object(g.useQuery)(E).data,U=Object(b.h)((function(e){return e.global})),C=U.currentDropzone,x=(U.theme,Object(b.g)()),I=!(null==C||null==(n=C.currentUser)||null==(t=n.user)||null==(r=t.rigs)||!r.length),R=!(null==C||null==(l=C.currentUser)||null==(o=l.user)||!o.exitWeight),q=!I||!R;return c.a.createElement(c.a.Fragment,null,c.a.createElement(s.a.Header,null,z?c.a.createElement(s.a.BackAction,{onPress:P.goBack}):null,c.a.createElement(s.a.Content,{title:w.descriptor.options.title}),c.a.createElement(m.a,{onDismiss:function(){return k(!1)},visible:O,anchor:c.a.createElement(d.a,{onPress:function(){return k(!0)},style:{color:"white",marginRight:8}},null==C?void 0:C.name)},null==D||null==(i=D.dropzones)||null==(v=i.edges)?void 0:v.map((function(e){var n;return c.a.createElement(m.a.Item,{title:null==e||null==(n=e.node)?void 0:n.name,onPress:function(){x(b.b.setDropzone(null==e?void 0:e.node)),k(!1)}})})))),q&&c.a.createElement(h.a,{style:y.warning},c.a.createElement(p.a,null,"You need to complete your profile"),c.a.createElement(f.a,{color:"black",mode:"outlined",onPress:function(){return P.navigate("Profile")}},"Take me there")))}},500:function(e,n,t){"use strict";t.r(n),t.d(n,"default",(function(){return m}));var r=t(401),l=t(0),a=t(452),o=t(60),i=l.lazy((function(){return Promise.all([t.e(0),t.e(1),t.e(3),t.e(8)]).then(t.bind(null,480))})),u=l.lazy((function(){return Promise.all([t.e(2),t.e(35)]).then(t.bind(null,511))})),c=l.lazy((function(){return Promise.all([t.e(0),t.e(18)]).then(t.bind(null,531))})),s=Object(r.a)();function m(){var e,n=Object(o.h)((function(e){return e.global})).currentDropzone;return l.createElement(s.Navigator,{screenOptions:{headerShown:!0,header:function(e){return l.createElement(a.a,e)},cardStyle:{flex:1}}},l.createElement(s.Screen,{name:"ProfileScreen",component:i,options:{title:"Profile"},initialParams:{userId:null==n||null==(e=n.currentUser)?void 0:e.id}}),l.createElement(s.Screen,{name:"UpdateUserScreen",component:c,options:{title:"Edit profile"}}),l.createElement(s.Screen,{name:"RigScreen",component:u,options:{title:"Rig"}}))}}}]);
//# sourceMappingURL=43.479a4a05.chunk.js.map