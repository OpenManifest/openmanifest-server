(this.webpackJsonp=this.webpackJsonp||[]).push([[21],{629:function(e,t,n){"use strict";n.d(t,"b",(function(){return J})),n.d(t,"a",(function(){return Q})),n.d(t,"c",(function(){return d}));var o=n(0),r=n(19),a=n(12),i=n.n(a),l=n(1),s=n(2),c=o.createContext({goTo:function(){return null},index:0});function d(){return Object(o.useContext)(c).goTo}var p=n(4),u=n.n(p),m=n(11),f=n.n(m),b=n(10),h=n(9),g=n(77),y=n(119),v=n(78),E=n(20),x=n.n(E);function w(e){var t,n=e.left,o=e.width;return{transform:[{scaleX:o},{translateX:(t=n/o,Math.round(100*t+Number.EPSILON)/100||0)}]}}var C,T=n(44),k=n(60);function O(){return(O=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}try{C=b.a.createAnimatedComponent(n(463).default)}catch(X){var S=!1;C=function(e){var t=e.name,n=f()(e,["name"]);return S||(/(Cannot find module|Module not found|Cannot resolve module)/.test(X.message)||console.error(X),console.warn("Tried to use the icon '"+t+"' in a component from 'react-native-paper-tabs', but 'react-native-vector-icons/MaterialCommunityIcons' could not be loaded.","To remove this warning, try installing 'react-native-vector-icons' or use another method to specify icon: https://callstack.github.io/react-native-paper/icons.html."),S=!0),o.createElement(b.a.Text,O({},n,{selectable:!1}),"\u25a1")}}var P=l.a.create({icon:{backgroundColor:"transparent"}}),R=function(e){var t=e.name,n=e.color,r=e.size,a=e.style,i=f()(e,["name","color","size","style"]);return o.createElement(C,O({selectable:!1,name:t,color:n,size:r,style:[{lineHeight:r},P.icon,a]},i))};function j(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function N(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?j(Object(n),!0).forEach((function(t){u()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):j(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var I=b.a.createAnimatedComponent(T.a);function D(e){var t=e.tab,n=e.tabIndex,r=e.active,a=e.goTo,i=e.onTabLayout,l=e.activeColor,c=e.textColor,d=e.theme,p=e.position,u=e.offset,m=e.childrenCount,f=e.uppercase,b=e.mode,h=e.iconPosition,g=e.showTextLabel,y=o.useMemo((function(){return x()(l).alpha(.32).rgb().string()}),[l]),v=function(e){var t=e.activeColor,n=e.active,r=e.textColor;return o.useMemo((function(){return{color:n?t:r,opacity:n?1:.6}}),[n,t,r])}({active:r,position:p,offset:u,activeColor:l,textColor:c,tabIndex:n,childrenCount:m}),E=v.color,w=v.opacity;return o.createElement(s.a,{key:t.props.label,style:[L.tabRoot,"fixed"===b&&L.tabRootFixed],onLayout:function(e){return i(n,e)}},o.createElement(k.a,{onPress:function(){return a(n)},onPressIn:function(){},style:[L.touchableRipple,"top"===h&&L.touchableRippleTop],rippleColor:y,accessibilityTraits:"button",accessibilityRole:"button",accessibilityComponentType:"button",accessibilityLabel:t.props.label,accessibilityState:{selected:r},testID:"tab_"+n},o.createElement(s.a,{style:[L.touchableRippleInner,"top"===h&&L.touchableRippleInnerTop]},t.props.icon?o.createElement(s.a,{style:[L.iconContainer,"top"!==h&&L.marginRight]},o.createElement(R,{selectable:!1,accessibilityElementsHidden:!0,importantForAccessibility:"no",name:t.props.icon||"",style:{color:E,opacity:w},size:24})):null,g?o.createElement(I,{selectable:!1,style:[L.text,"top"===h&&L.textTop,N(N({},d.fonts.medium),{},{color:E,opacity:w})]},f?t.props.label.toUpperCase():t.props.label):null)))}var L=l.a.create({tabRoot:{position:"relative"},tabRootFixed:{flex:1},touchableRipple:{height:48,justifyContent:"center",alignItems:"center"},touchableRippleTop:{height:72},touchableRippleInner:{flexDirection:"row",alignItems:"center",justifyContent:"center",paddingRight:16,paddingLeft:16,minWidth:90,maxWidth:360},touchableRippleInnerTop:{flexDirection:"column"},iconContainer:{width:24,height:24},text:N({textAlign:"center",letterSpacing:1},h.a.select({web:{transitionDuration:"150ms",transitionProperty:"all"},default:{}})),textTop:{marginTop:6},marginRight:{marginRight:8}});function z(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function U(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?z(Object(n),!0).forEach((function(t){u()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):z(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function M(e){var t=e.index,n=e.goTo,r=e.children,a=e.position,c=e.offset,d=e.theme,p=e.dark,m=e.style,h=e.iconPosition,E=e.showTextLabel,C=e.showLeadingSpace,T=e.uppercase,k=e.mode,O=d.colors,S=d.dark,P=d.mode,R=l.a.flatten(m)||{},j=R.backgroundColor,N=R.elevation,I=void 0===N?4:N,L=f()(R,["backgroundColor","elevation"]),z=j||(S&&"adaptive"===P?Object(y.a)(I,O.surface):O.primary),M=O.primary===z,F=("boolean"===typeof p?p:"transparent"!==z&&!x()(z).isLight())?"#fff":"#000",V=M?F:d.colors.primary,H=o.useRef(null),W=o.useRef(0),J=o.useRef(null),Q=o.useRef(null),X=o.useState(null),$=i()(X,2),_=$[0],q=$[1],B=function(e){var t=e.index,n=e.layouts,r=o.useRef(null),a=o.useCallback((function(){if(r.current&&n.current){var e=n.current[t];e&&r.current.setNativeProps({style:w({left:e.x,width:e.width})})}}),[t,r,n]);return[r,a,null]}({tabsLayout:_,layouts:Q,index:t,offset:c,position:a,childrenCount:r.length}),G=i()(B,3),K=G[0],Y=G[1],Z=G[2],ee=o.useCallback((function(e){q(e.nativeEvent.layout)}),[q]),te=o.useCallback((function(e,t){Q.current=U(U({},Q.current),{},u()({},e,t.nativeEvent.layout)),Y()}),[Q,Y]),ne=o.useCallback((function(e){if(Q.current&&"scrollable"===k){var n=Q.current[t];if(n&&J.current&&_){var o=_.width,r=W.current;if("next"===e){var a,i=null===(a=Q.current)||void 0===a?void 0:a[t+1];i&&(n=i)}else if("prev"===e){var l,s=null===(l=Q.current)||void 0===l?void 0:l[t-1];s&&(n=s)}var c=n.x-r,d=c,p=-o+c+n.width;p>-50?J.current.scrollTo({x:r+p+50,y:0,animated:!0}):d<50&&J.current.scrollTo({x:r+d-50,y:0,animated:!0})}}}),[k,Q,t,J,W,_]);return o.useEffect((function(){ne()}),[ne]),o.useEffect((function(){Y()}),[Y]),o.createElement(s.a,{style:A.relative},o.createElement(v.a,{style:[{backgroundColor:z,elevation:I},L,A.tabs,"top"===h&&A.tabsTopIcon],onLayout:ee},o.createElement(g.a,{ref:J,contentContainerStyle:"fixed"===k?A.fixedContentContainerStyle:void 0,onContentSizeChange:function(e){H.current=e},onScroll:function(e){W.current=e.nativeEvent.contentOffset.x},scrollEventThrottle:25,horizontal:!0,showsHorizontalScrollIndicator:!1,alwaysBounceHorizontal:"scrollable"===k,scrollEnabled:"scrollable"===k},"scrollable"===k&&C?o.createElement(s.a,{style:A.scrollablePadding}):null,o.Children.map(r,(function(e,i){return o.createElement(D,{theme:d,tabIndex:i,tab:e,active:t===i,onTabLayout:te,goTo:n,activeColor:V,textColor:F,position:a,offset:c,childrenCount:r.length,uppercase:T,iconPosition:h,showTextLabel:E,mode:k})})),o.createElement(b.a.View,{ref:K,pointerEvents:"none",style:[A.indicator,{backgroundColor:V},Z]})),o.createElement(b.a.View,{style:[A.removeTopShadow,{height:I,backgroundColor:z,top:-I}]})))}var A=l.a.create({relative:{position:"relative"},removeTopShadow:{position:"absolute",left:0,right:0,zIndex:2},scrollablePadding:{width:52},tabs:{height:48},tabsTopIcon:{height:72},fixedContentContainerStyle:{flex:1},indicator:U({position:"absolute",height:2,width:1,left:0,bottom:0},h.a.select({web:{backgroundColor:"transparent",transitionDuration:"150ms",transitionProperty:"all",transformOrigin:"left",willChange:"transform"},default:{}}))});var F=l.a.create({root:{flex:1}}),V=function(e){var t=e.theme,n=e.dark,r=e.style,a=e.defaultIndex,l=e.onChangeIndex,d=e.iconPosition,p=e.showTextLabel,u=e.showLeadingSpace,m=e.uppercase,f=e.mode,b=o.useState(a||0),h=i()(b,2),g=h[0],y=h[1],v=o.useCallback((function(e){y(e),l(e)}),[y,l]),E=e.children,x=E[g];if(!x||!x)return null;var w={index:g,goTo:v,children:E,theme:t,dark:n,style:r,offset:void 0,position:void 0,iconPosition:d,showTextLabel:p,showLeadingSpace:u,uppercase:m,mode:f};return o.createElement(s.a,{style:F.root},o.createElement(M,w),o.createElement(c.Provider,{value:{goTo:v,index:g}},x))},H=function(){var e={};return{set:function(t,n){e[t]=n},get:function(t){return e[t]}}}();function W(e,t){return t?H.get(t)||e||0:e||0}var J=Object(r.c)((function(e){var t=e.onChangeIndex,n=e.children,r=e.persistKey,a=e.theme,i=e.dark,l=e.style,s=e.defaultIndex,c=e.mode,d=void 0===c?"fixed":c,p=e.uppercase,u=void 0===p||p,m=e.iconPosition,f=void 0===m?"leading":m,b=e.showTextLabel,g=void 0===b||b,y=e.showLeadingSpace,v=void 0===y||y,E=o.useCallback((function(e){r&&"web"===h.a.OS&&H.set(r,e),null===t||void 0===t||t(e)}),[r,t]);return o.createElement(V,{style:l,dark:i,theme:a,defaultIndex:W(s,r),onChangeIndex:E,uppercase:u,iconPosition:f,showTextLabel:g,showLeadingSpace:v,mode:d},n)}));function Q(e){var t=e.children;return o.Children.only(t)}},774:function(e,t,n){"use strict";n.r(t),n.d(t,"default",(function(){return E}));var o,r=n(36),a=n.n(r),i=n(47),l=n(56),s=n(37),c=n(0),d=n(1),p=n(388),u=n(104),m=n(24),f=n(629),b=n(7),h=n(158),g=n(387),y=n(124),v=Object(s.a)(o||(o=a()(["\n  query QueryDropzoneRigs(\n    $dropzoneId: Int!\n  ) {\n    dropzone(id: $dropzoneId) {\n      id\n      roles {\n        id\n        name\n        permissions\n      }\n    }\n  }\n"])));function E(){var e,t,n=Object(b.c)((function(e){return e.global})),o=Object(i.useQuery)(v,{variables:{dropzoneId:Number(n.currentDropzoneId)}}),r=o.data,a=o.loading,s=o.refetch,d=Object(l.useIsFocused)();return c.useEffect((function(){d&&s()}),[d]),a?c.createElement(p.a,{indeterminate:!0,color:n.theme.colors.accent}):c.createElement(f.b,{defaultIndex:0,mode:"scrollable"},null==r||null==(e=r.dropzone)||null==(t=e.roles)?void 0:t.map((function(e){var t;return c.createElement(f.a,{label:Object(y.capitalize)(null==(t=e.name)?void 0:t.replace("_"," ")),key:"permission-tab-role-"+e.id},c.createElement(h.a,{contentContainerStyle:{maxWidth:500,width:"100%",alignSelf:"center"}},c.createElement(u.a,{style:x.card},c.createElement(m.b.Subheader,null,"User Management"),c.createElement(g.a,{role:e,permissionName:"readUser",description:"View other users' profiles",title:"View Users"}),c.createElement(g.a,{role:e,permissionName:"updateUser",description:"Update other users",title:"Update Users"})),c.createElement(u.a,{style:x.card},c.createElement(m.b.Section,{title:"Manifest",style:{width:"100%"}},c.createElement(m.b.Accordion,{title:"Loads"},c.createElement(g.a,{role:e,permissionName:"readLoad",description:"See available loads on the manifest screen",title:"View Load"}),c.createElement(g.a,{role:e,permissionName:"createLoad",title:"Create Loads"}),c.createElement(g.a,{role:e,permissionName:"updateLoad",description:"Dispatch loads, update load master, change pilot / plane, etc",title:"Update Loads"}),c.createElement(g.a,{role:e,permissionName:"deleteLoad",description:"Permanently delete existing loads",title:"Delete Load"})),c.createElement(m.b.Accordion,{title:"Manifesting"},c.createElement(g.a,{role:e,permissionName:"createSlot",description:"Create a slot for himself/herself only",title:"Manifest self"}),c.createElement(g.a,{role:e,permissionName:"updateSlot",description:"Update own slot after manifesting themselves",title:"Update own slot"}),c.createElement(g.a,{role:e,permissionName:"deleteSlot",description:"Take themselves off the load",title:"Remove own slot"}),c.createElement(g.a,{role:e,permissionName:"createUserSlot",description:"Manifest other users, e.g yourself + others",title:"Manifest other people"}),c.createElement(g.a,{role:e,permissionName:"createUserSlotWithSelf",description:"Allow manifesting others only if the user is part of the group",title:"Manifest own groups"}),c.createElement(g.a,{role:e,permissionName:"updateUserSlot",description:"Update other people's slots on a load",title:"Update other users slot"}),c.createElement(g.a,{role:e,permissionName:"deleteUserSlot",description:"Delete other users' slots off a load",title:"Take others off the load"}),c.createElement(g.a,{role:e,permissionName:"createStudentSlot",description:"Manifest a student on a load",title:"Manifest students"}),c.createElement(g.a,{role:e,permissionName:"updateStudentSlot",description:"Make changes to an already manifested student",title:"Update student slots"}),c.createElement(g.a,{role:e,permissionName:"deleteStudentSlot",description:"Take a student off the load",title:"Remove student slots"})))),c.createElement(u.a,{style:x.card},c.createElement(m.b.Section,{title:"Administration",style:{width:"100%"}},c.createElement(m.b.Accordion,{title:"Dropzone"},c.createElement(g.a,{role:e,permissionName:"updateDropzone",description:"Change dropzone name, visibility, and branding",title:"Update Dropzone"}),c.createElement(g.a,{role:e,permissionName:"deleteDropzone",description:"Permanently delete dropzone",title:"Delete Dropzone"})),c.createElement(m.b.Accordion,{title:"Ticket types"},c.createElement(g.a,{role:e,permissionName:"createTicketType",description:"Create new jump tickets",title:"Create Ticket"}),c.createElement(g.a,{role:e,permissionName:"updateTicketType",description:"Make changes to existing ticket types, including prices",title:"Update Tickets"}),c.createElement(g.a,{role:e,permissionName:"deleteTicketType",description:"Delete existing ticket types",title:"Remove Tickets"})),c.createElement(m.b.Accordion,{title:"Ticket addons"},c.createElement(g.a,{role:e,permissionName:"createExtra",description:"Set up new ticket addons",title:"Create Ticket addon"}),c.createElement(g.a,{role:e,permissionName:"updateExtra",description:"Make changes to existing ticket addons, including prices",title:"Update Ticket addons"}),c.createElement(g.a,{role:e,permissionName:"deleteExtra",description:"Delete existing ticket addons",title:"Remove Ticket addons"})),c.createElement(m.b.Accordion,{title:"Planes"},c.createElement(g.a,{role:e,permissionName:"createPlane",description:"Add new aircrafts",title:"Create Aircraft"}),c.createElement(g.a,{role:e,permissionName:"updatePlane",description:"Make changes to existing aircrafts",title:"Update Aircraft"}),c.createElement(g.a,{role:e,permissionName:"deletePlane",description:"Remove existing aircrafts",title:"Remove Aircraft"})),c.createElement(m.b.Accordion,{title:"Rigs"},c.createElement(g.a,{role:e,permissionName:"createDropzoneRig",description:"Create dropzone managed rigs, e.g tandem and student rigs",title:"Create Rig"}),c.createElement(g.a,{role:e,permissionName:"updateDropzoneRig",description:"Make changes to existing student and tandem rigs",title:"Update Rigs"}),c.createElement(g.a,{role:e,permissionName:"deleteDropzoneRig",description:"Delete existing student and tandem rigs",title:"Remove Rigs"}),c.createElement(g.a,{role:e,permissionName:"updateFormTemplate",description:"Make changes to the rig inspection template",title:"Modify Rig Inspection Form"}))))))})))}var x=d.a.create({container:{flex:1,display:"flex"},card:{width:"100%",marginVertical:16},content:{flexGrow:1},fab:{position:"absolute",margin:16,right:0,bottom:0},empty:{flex:1,alignItems:"center",justifyContent:"center",width:"100%",height:"100%"}})}}]);
//# sourceMappingURL=21.d816dd79.chunk.js.map