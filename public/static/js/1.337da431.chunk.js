(this.webpackJsonp=this.webpackJsonp||[]).push([[1],{462:function(e,t,n){"use strict";var r=n(11),o=n.n(r),a=n(0),i=n(1),l=n(2),c=n(44),s=n(60);function u(){return(u=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var p=function(e){var t=e.children,n=e.style,r=e.numeric,i=o()(e,["children","style","numeric"]);return a.createElement(s.a,u({},i,{style:[d.container,r&&d.right,n]}),a.createElement(c.a,{numberOfLines:1},t))};p.displayName="DataTable.Cell";var d=i.a.create({container:{flex:1,flexDirection:"row",alignItems:"center"},right:{justifyContent:"flex-end"}}),f=p,m=n(20),h=n.n(m),b=n(26),y=n(19);function v(){return(v=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var g=function(e){var t=e.children,n=e.style,r=e.theme,i=o()(e,["children","style","theme"]),c=h()(r.dark?b.h:b.a).alpha(.12).rgb().string();return a.createElement(l.a,v({},i,{style:[x.header,{borderBottomColor:c},n]}),t)};g.displayName="DataTable.Header";var x=i.a.create({header:{flexDirection:"row",height:48,paddingHorizontal:16,borderBottomWidth:2*i.a.hairlineWidth}}),w=Object(y.c)(g),O=n(10),P=n(72),C=n(27),E=n(82);function j(){return(j=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var T=function(e){var t=e.numeric,n=e.children,r=e.onPress,i=e.sortDirection,s=e.theme,u=e.style,p=e.numberOfLines,d=void 0===p?1:p,f=o()(e,["numeric","children","onPress","sortDirection","theme","style","numberOfLines"]),m=a.useRef(new O.a.Value("ascending"===i?0:1)).current;a.useEffect((function(){O.a.timing(m,{toValue:"ascending"===i?0:1,duration:150,useNativeDriver:!0}).start()}),[i,m]);var b=h()(s.colors.text).alpha(.6).rgb().string(),y=m.interpolate({inputRange:[0,1],outputRange:["0deg","180deg"]}),v=i?a.createElement(O.a.View,{style:[L.icon,{transform:[{rotate:y}]}]},a.createElement(E.b,{name:"arrow-up",size:16,color:s.colors.text,direction:C.a.isRTL?"rtl":"ltr"})):null;return a.createElement(P.a,j({disabled:!r,onPress:r},f),a.createElement(l.a,{style:[L.container,t&&L.right,u]},v,a.createElement(c.a,{style:[L.cell,i?L.sorted:{color:b}],numberOfLines:d},n)))};T.displayName="DataTable.Title";var L=i.a.create({container:{flex:1,flexDirection:"row",alignContent:"center",paddingVertical:12},right:{justifyContent:"flex-end"},cell:{height:24,lineHeight:24,fontSize:12,fontWeight:"500",alignItems:"center"},sorted:{marginLeft:8},icon:{height:24,justifyContent:"center"}}),I=Object(y.c)(T),k=n(160);function R(){return(R=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var S=function(e){var t=e.label,n=e.page,r=e.numberOfPages,i=e.onPageChange,s=e.style,u=e.theme,p=o()(e,["label","page","numberOfPages","onPageChange","style","theme"]),d=h()(u.colors.text).alpha(.6).rgb().string();return a.createElement(l.a,R({},p,{style:[A.container,s]}),a.createElement(c.a,{style:[A.label,{color:d}],numberOfLines:1},t),a.createElement(k.a,{icon:function(e){var t=e.size,n=e.color;return a.createElement(E.b,{name:"chevron-left",color:n,size:t,direction:C.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===n,onPress:function(){return i(n-1)}}),a.createElement(k.a,{icon:function(e){var t=e.size,n=e.color;return a.createElement(E.b,{name:"chevron-right",color:n,size:t,direction:C.a.isRTL?"rtl":"ltr"})},color:u.colors.text,disabled:0===r||n===r-1,onPress:function(){return i(n+1)}}))};S.displayName="DataTable.Pagination";var A=i.a.create({container:{justifyContent:"flex-end",flexDirection:"row",alignItems:"center",paddingLeft:16},label:{fontSize:12,marginRight:44}}),D=Object(y.c)(S);function H(){return(H=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var M=i.a.create({container:{borderStyle:"solid",borderBottomWidth:i.a.hairlineWidth,minHeight:48,paddingHorizontal:16},content:{flex:1,flexDirection:"row"}}),V=Object(y.c)((function(e){var t=e.onPress,n=e.style,r=e.theme,i=e.children,c=e.pointerEvents,u=o()(e,["onPress","style","theme","children","pointerEvents"]),p=h()(r.dark?b.h:b.a).alpha(.12).rgb().string();return a.createElement(s.a,H({},u,{onPress:t,style:[M.container,{borderBottomColor:p},n]}),a.createElement(l.a,{style:M.content,pointerEvents:c},i))}));function z(){return(z=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var _=function(e){var t=e.children,n=e.style,r=o()(e,["children","style"]);return a.createElement(l.a,z({},r,{style:[F.container,n]}),t)};_.Header=w,_.Title=I,_.Row=V,_.Cell=f,_.Pagination=D;var F=i.a.create({container:{width:"100%"}});t.a=_},629:function(e,t,n){"use strict";n.d(t,"b",(function(){return q})),n.d(t,"a",(function(){return Q})),n.d(t,"c",(function(){return u}));var r=n(0),o=n(19),a=n(12),i=n.n(a),l=n(1),c=n(2),s=r.createContext({goTo:function(){return null},index:0});function u(){return Object(r.useContext)(s).goTo}var p=n(4),d=n.n(p),f=n(11),m=n.n(f),h=n(10),b=n(9),y=n(77),v=n(119),g=n(78),x=n(20),w=n.n(x);function O(e){var t,n=e.left,r=e.width;return{transform:[{scaleX:r},{translateX:(t=n/r,Math.round(100*t+Number.EPSILON)/100||0)}]}}var P,C=n(44),E=n(60);function j(){return(j=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}try{P=h.a.createAnimatedComponent(n(463).default)}catch(B){var T=!1;P=function(e){var t=e.name,n=m()(e,["name"]);return T||(/(Cannot find module|Module not found|Cannot resolve module)/.test(B.message)||console.error(B),console.warn("Tried to use the icon '"+t+"' in a component from 'react-native-paper-tabs', but 'react-native-vector-icons/MaterialCommunityIcons' could not be loaded.","To remove this warning, try installing 'react-native-vector-icons' or use another method to specify icon: https://callstack.github.io/react-native-paper/icons.html."),T=!0),r.createElement(h.a.Text,j({},n,{selectable:!1}),"\u25a1")}}var L=l.a.create({icon:{backgroundColor:"transparent"}}),I=function(e){var t=e.name,n=e.color,o=e.size,a=e.style,i=m()(e,["name","color","size","style"]);return r.createElement(P,j({selectable:!1,name:t,color:n,size:o,style:[{lineHeight:o},L.icon,a]},i))};function k(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function R(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?k(Object(n),!0).forEach((function(t){d()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):k(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var S=h.a.createAnimatedComponent(C.a);function A(e){var t=e.tab,n=e.tabIndex,o=e.active,a=e.goTo,i=e.onTabLayout,l=e.activeColor,s=e.textColor,u=e.theme,p=e.position,d=e.offset,f=e.childrenCount,m=e.uppercase,h=e.mode,b=e.iconPosition,y=e.showTextLabel,v=r.useMemo((function(){return w()(l).alpha(.32).rgb().string()}),[l]),g=function(e){var t=e.activeColor,n=e.active,o=e.textColor;return r.useMemo((function(){return{color:n?t:o,opacity:n?1:.6}}),[n,t,o])}({active:o,position:p,offset:d,activeColor:l,textColor:s,tabIndex:n,childrenCount:f}),x=g.color,O=g.opacity;return r.createElement(c.a,{key:t.props.label,style:[D.tabRoot,"fixed"===h&&D.tabRootFixed],onLayout:function(e){return i(n,e)}},r.createElement(E.a,{onPress:function(){return a(n)},onPressIn:function(){},style:[D.touchableRipple,"top"===b&&D.touchableRippleTop],rippleColor:v,accessibilityTraits:"button",accessibilityRole:"button",accessibilityComponentType:"button",accessibilityLabel:t.props.label,accessibilityState:{selected:o},testID:"tab_"+n},r.createElement(c.a,{style:[D.touchableRippleInner,"top"===b&&D.touchableRippleInnerTop]},t.props.icon?r.createElement(c.a,{style:[D.iconContainer,"top"!==b&&D.marginRight]},r.createElement(I,{selectable:!1,accessibilityElementsHidden:!0,importantForAccessibility:"no",name:t.props.icon||"",style:{color:x,opacity:O},size:24})):null,y?r.createElement(S,{selectable:!1,style:[D.text,"top"===b&&D.textTop,R(R({},u.fonts.medium),{},{color:x,opacity:O})]},m?t.props.label.toUpperCase():t.props.label):null)))}var D=l.a.create({tabRoot:{position:"relative"},tabRootFixed:{flex:1},touchableRipple:{height:48,justifyContent:"center",alignItems:"center"},touchableRippleTop:{height:72},touchableRippleInner:{flexDirection:"row",alignItems:"center",justifyContent:"center",paddingRight:16,paddingLeft:16,minWidth:90,maxWidth:360},touchableRippleInnerTop:{flexDirection:"column"},iconContainer:{width:24,height:24},text:R({textAlign:"center",letterSpacing:1},b.a.select({web:{transitionDuration:"150ms",transitionProperty:"all"},default:{}})),textTop:{marginTop:6},marginRight:{marginRight:8}});function H(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function M(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?H(Object(n),!0).forEach((function(t){d()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):H(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function V(e){var t=e.index,n=e.goTo,o=e.children,a=e.position,s=e.offset,u=e.theme,p=e.dark,f=e.style,b=e.iconPosition,x=e.showTextLabel,P=e.showLeadingSpace,C=e.uppercase,E=e.mode,j=u.colors,T=u.dark,L=u.mode,I=l.a.flatten(f)||{},k=I.backgroundColor,R=I.elevation,S=void 0===R?4:R,D=m()(I,["backgroundColor","elevation"]),H=k||(T&&"adaptive"===L?Object(v.a)(S,j.surface):j.primary),V=j.primary===H,_=("boolean"===typeof p?p:"transparent"!==H&&!w()(H).isLight())?"#fff":"#000",F=V?_:u.colors.primary,N=r.useRef(null),W=r.useRef(0),q=r.useRef(null),Q=r.useRef(null),B=r.useState(null),G=i()(B,2),U=G[0],J=G[1],X=function(e){var t=e.index,n=e.layouts,o=r.useRef(null),a=r.useCallback((function(){if(o.current&&n.current){var e=n.current[t];e&&o.current.setNativeProps({style:O({left:e.x,width:e.width})})}}),[t,o,n]);return[o,a,null]}({tabsLayout:U,layouts:Q,index:t,offset:s,position:a,childrenCount:o.length}),K=i()(X,3),Y=K[0],Z=K[1],$=K[2],ee=r.useCallback((function(e){J(e.nativeEvent.layout)}),[J]),te=r.useCallback((function(e,t){Q.current=M(M({},Q.current),{},d()({},e,t.nativeEvent.layout)),Z()}),[Q,Z]),ne=r.useCallback((function(e){if(Q.current&&"scrollable"===E){var n=Q.current[t];if(n&&q.current&&U){var r=U.width,o=W.current;if("next"===e){var a,i=null===(a=Q.current)||void 0===a?void 0:a[t+1];i&&(n=i)}else if("prev"===e){var l,c=null===(l=Q.current)||void 0===l?void 0:l[t-1];c&&(n=c)}var s=n.x-o,u=s,p=-r+s+n.width;p>-50?q.current.scrollTo({x:o+p+50,y:0,animated:!0}):u<50&&q.current.scrollTo({x:o+u-50,y:0,animated:!0})}}}),[E,Q,t,q,W,U]);return r.useEffect((function(){ne()}),[ne]),r.useEffect((function(){Z()}),[Z]),r.createElement(c.a,{style:z.relative},r.createElement(g.a,{style:[{backgroundColor:H,elevation:S},D,z.tabs,"top"===b&&z.tabsTopIcon],onLayout:ee},r.createElement(y.a,{ref:q,contentContainerStyle:"fixed"===E?z.fixedContentContainerStyle:void 0,onContentSizeChange:function(e){N.current=e},onScroll:function(e){W.current=e.nativeEvent.contentOffset.x},scrollEventThrottle:25,horizontal:!0,showsHorizontalScrollIndicator:!1,alwaysBounceHorizontal:"scrollable"===E,scrollEnabled:"scrollable"===E},"scrollable"===E&&P?r.createElement(c.a,{style:z.scrollablePadding}):null,r.Children.map(o,(function(e,i){return r.createElement(A,{theme:u,tabIndex:i,tab:e,active:t===i,onTabLayout:te,goTo:n,activeColor:F,textColor:_,position:a,offset:s,childrenCount:o.length,uppercase:C,iconPosition:b,showTextLabel:x,mode:E})})),r.createElement(h.a.View,{ref:Y,pointerEvents:"none",style:[z.indicator,{backgroundColor:F},$]})),r.createElement(h.a.View,{style:[z.removeTopShadow,{height:S,backgroundColor:H,top:-S}]})))}var z=l.a.create({relative:{position:"relative"},removeTopShadow:{position:"absolute",left:0,right:0,zIndex:2},scrollablePadding:{width:52},tabs:{height:48},tabsTopIcon:{height:72},fixedContentContainerStyle:{flex:1},indicator:M({position:"absolute",height:2,width:1,left:0,bottom:0},b.a.select({web:{backgroundColor:"transparent",transitionDuration:"150ms",transitionProperty:"all",transformOrigin:"left",willChange:"transform"},default:{}}))});var _=l.a.create({root:{flex:1}}),F=function(e){var t=e.theme,n=e.dark,o=e.style,a=e.defaultIndex,l=e.onChangeIndex,u=e.iconPosition,p=e.showTextLabel,d=e.showLeadingSpace,f=e.uppercase,m=e.mode,h=r.useState(a||0),b=i()(h,2),y=b[0],v=b[1],g=r.useCallback((function(e){v(e),l(e)}),[v,l]),x=e.children,w=x[y];if(!w||!w)return null;var O={index:y,goTo:g,children:x,theme:t,dark:n,style:o,offset:void 0,position:void 0,iconPosition:u,showTextLabel:p,showLeadingSpace:d,uppercase:f,mode:m};return r.createElement(c.a,{style:_.root},r.createElement(V,O),r.createElement(s.Provider,{value:{goTo:g,index:y}},w))},N=function(){var e={};return{set:function(t,n){e[t]=n},get:function(t){return e[t]}}}();function W(e,t){return t?N.get(t)||e||0:e||0}var q=Object(o.c)((function(e){var t=e.onChangeIndex,n=e.children,o=e.persistKey,a=e.theme,i=e.dark,l=e.style,c=e.defaultIndex,s=e.mode,u=void 0===s?"fixed":s,p=e.uppercase,d=void 0===p||p,f=e.iconPosition,m=void 0===f?"leading":f,h=e.showTextLabel,y=void 0===h||h,v=e.showLeadingSpace,g=void 0===v||v,x=r.useCallback((function(e){o&&"web"===b.a.OS&&N.set(o,e),null===t||void 0===t||t(e)}),[o,t]);return r.createElement(F,{style:l,dark:i,theme:a,defaultIndex:W(c,o),onChangeIndex:x,uppercase:d,iconPosition:m,showTextLabel:y,showLeadingSpace:g,mode:u},n)}));function Q(e){var t=e.children;return r.Children.only(t)}},631:function(e,t,n){"use strict";var r,o,a;n.d(t,"a",(function(){return r})),function(e){e.All="All",e.Videos="Videos",e.Images="Images"}(r||(r={})),function(e){e[e.Passthrough=0]="Passthrough",e[e.LowQuality=1]="LowQuality",e[e.MediumQuality=2]="MediumQuality",e[e.HighestQuality=3]="HighestQuality",e[e.H264_640x480=4]="H264_640x480",e[e.H264_960x540=5]="H264_960x540",e[e.H264_1280x720=6]="H264_1280x720",e[e.H264_1920x1080=7]="H264_1920x1080",e[e.H264_3840x2160=8]="H264_3840x2160",e[e.HEVC_1920x1080=9]="HEVC_1920x1080",e[e.HEVC_3840x2160=10]="HEVC_3840x2160"}(o||(o={})),function(e){e[e.High=0]="High",e[e.Medium=1]="Medium",e[e.Low=2]="Low",e[e.VGA640x480=3]="VGA640x480",e[e.IFrame1280x720=4]="IFrame1280x720",e[e.IFrame960x540=5]="IFrame960x540"}(a||(a={}))},763:function(e,t,n){"use strict";n.d(t,"b",(function(){return E})),n.d(t,"a",(function(){return j}));n(12);var r=n(8),o=n.n(r),a=(n(423),n(600)),i=n(227),l=n(4),c=n.n(l),s="undefined"!=typeof crypto&&crypto.getRandomValues&&crypto.getRandomValues.bind(crypto)||"undefined"!=typeof msCrypto&&"function"==typeof msCrypto.getRandomValues&&msCrypto.getRandomValues.bind(msCrypto),u=new Uint8Array(16);function p(){if(!s)throw new Error("crypto.getRandomValues() not supported. See https://github.com/uuidjs/uuid#getrandomvalues-not-supported");return s(u)}for(var d=[],f=0;f<256;++f)d[f]=(f+256).toString(16).substr(1);var m=function(e,t){var n=t||0,r=d;return[r[e[n++]],r[e[n++]],r[e[n++]],r[e[n++]],"-",r[e[n++]],r[e[n++]],"-",r[e[n++]],r[e[n++]],"-",r[e[n++]],r[e[n++]],"-",r[e[n++]],r[e[n++]],r[e[n++]],r[e[n++]],r[e[n++]],r[e[n++]]].join("")};var h,b=function(e,t,n){var r=t&&n||0;"string"==typeof e&&(t="binary"===e?new Array(16):null,e=null);var o=(e=e||{}).random||(e.rng||p)();if(o[6]=15&o[6]|64,o[8]=63&o[8]|128,t)for(var a=0;a<16;++a)t[r+a]=o[a];return t||m(o)},y=n(631);function v(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function g(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?v(Object(n),!0).forEach((function(t){c()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):v(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var x=(h={},c()(h,y.a.All,"video/mp4,video/quicktime,video/x-m4v,video/*,image/*"),c()(h,y.a.Images,"image/*"),c()(h,y.a.Videos,"video/mp4,video/quicktime,video/x-m4v,video/*"),h),w={get name(){return"ExponentImagePicker"},launchImageLibraryAsync:function(e){var t,n,r,a;return o.a.async((function(i){for(;;)switch(i.prev=i.next){case 0:return t=e.mediaTypes,n=void 0===t?y.a.Images:t,r=e.allowsMultipleSelection,a=void 0!==r&&r,i.next=3,o.a.awrap(P({mediaTypes:n,allowsMultipleSelection:a}));case 3:return i.abrupt("return",i.sent);case 4:case"end":return i.stop()}}),null,null,null,Promise)},launchCameraAsync:function(e){var t,n,r,a;return o.a.async((function(i){for(;;)switch(i.prev=i.next){case 0:return t=e.mediaTypes,n=void 0===t?y.a.Images:t,r=e.allowsMultipleSelection,a=void 0!==r&&r,i.next=3,o.a.awrap(P({mediaTypes:n,allowsMultipleSelection:a,capture:!0}));case 3:return i.abrupt("return",i.sent);case 4:case"end":return i.stop()}}),null,null,null,Promise)},getCameraPermissionsAsync:function(){return o.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return e.abrupt("return",O());case 1:case"end":return e.stop()}}),null,null,null,Promise)},requestCameraPermissionsAsync:function(){return o.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return e.abrupt("return",O());case 1:case"end":return e.stop()}}),null,null,null,Promise)},getMediaLibraryPermissionsAsync:function(e){return o.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return e.abrupt("return",O());case 1:case"end":return e.stop()}}),null,null,null,Promise)},requestMediaLibraryPermissionsAsync:function(e){return o.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return e.abrupt("return",O());case 1:case"end":return e.stop()}}),null,null,null,Promise)}};function O(){return{status:i.a.GRANTED,expires:"never",granted:!0,canAskAgain:!0}}function P(e){var t=e.mediaTypes,n=e.capture,r=void 0!==n&&n,a=e.allowsMultipleSelection,i=void 0!==a&&a,l=x[t],c=document.createElement("input");return c.style.display="none",c.setAttribute("type","file"),c.setAttribute("accept",l),c.setAttribute("id",b()),i&&c.setAttribute("multiple","multiple"),r&&c.setAttribute("capture","camera"),document.body.appendChild(c),new Promise((function(e,t){c.addEventListener("change",(function(){var t,n;return o.a.async((function(r){for(;;)switch(r.prev=r.next){case 0:if(!c.files){r.next=14;break}if(i){r.next=8;break}return r.next=4,o.a.awrap(C(c.files[0]));case 4:t=r.sent,e(g({cancelled:!1},t)),r.next=12;break;case 8:return r.next=10,o.a.awrap(Promise.all(Array.from(c.files).map(C)));case 10:n=r.sent,e({cancelled:!1,selected:n});case 12:r.next=15;break;case 14:e({cancelled:!0});case 15:document.body.removeChild(c);case 16:case"end":return r.stop()}}),null,null,null,Promise)}));var n=new MouseEvent("click");c.dispatchEvent(n)}))}function C(e){return new Promise((function(t,n){var r=new FileReader;r.onerror=function(){n(new Error("Failed to read the selected media because the operation failed."))},r.onload=function(e){var n=e.target,r=n.result,o=function(){return t({uri:r,width:0,height:0})};if("string"===typeof(null==n?void 0:n.result)){var a=new Image;a.src=n.result,a.onload=function(){var e,n;return t({uri:r,width:null!=(e=a.naturalWidth)?e:a.width,height:null!=(n=a.naturalHeight)?n:a.height})},a.onerror=function(){return o()}}else o()},r.readAsDataURL(e)}))}function E(){var e,t,n=arguments;return o.a.async((function(r){for(;;)switch(r.prev=r.next){case 0:return e=n.length>0&&void 0!==n[0]&&n[0],t="function"===typeof w.requestMediaLibaryPermissionsAsync?w.requestMediaLibaryPermissionsAsync:w.requestMediaLibraryPermissionsAsync,r.abrupt("return",t(e));case 3:case"end":return r.stop()}}),null,null,null,Promise)}function j(e){return o.a.async((function(t){for(;;)switch(t.prev=t.next){case 0:if(w.launchImageLibraryAsync){t.next=2;break}throw new a.a("ImagePicker","launchImageLibraryAsync");case 2:return t.next=4,o.a.awrap(w.launchImageLibraryAsync(null!=e?e:{}));case 4:return t.abrupt("return",t.sent);case 5:case"end":return t.stop()}}),null,null,null,Promise)}}}]);
//# sourceMappingURL=1.337da431.chunk.js.map