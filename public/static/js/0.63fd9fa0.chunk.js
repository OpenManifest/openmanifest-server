(this.webpackJsonp=this.webpackJsonp||[]).push([[0],{428:function(e,t,n){"use strict";var o=n(13),r=n.n(o),a=n(21),i=n.n(a),l=n(30),u=n.n(l),s=n(12),c=n.n(s),f=n(24),d=n.n(f),p=n(25),h=n.n(p),g=n(15),b=n.n(g),y=n(0),m=n.n(y),v=n(8),x=n(77),O=n(11),C=n(7),L=n.n(C),P=n(5),w=n(4),T=n(31),S=n(33),A=n.n(S),R=n(406);function j(){return(j=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}var E=m.a.createContext({style:{},isTextInputFocused:!1,forceFocus:function(){}}),F=function(e){var t=e.icon,n=e.topPosition,o=e.side,r=e.isTextInputFocused,a=e.forceFocus,i={style:L()({top:n},o,12),isTextInputFocused:r,forceFocus:a};return m.a.createElement(E.Provider,{value:i},t)},k=function(e){var t=e.name,n=e.onPress,o=e.forceTextInputFocus,a=e.color,i=r()(e,["name","onPress","forceTextInputFocus","color"]),l=m.a.useContext(E),u=l.style,s=l.isTextInputFocused,c=l.forceFocus,f=m.a.useCallback((function(){o&&!s&&c(),null===n||void 0===n||n()}),[o,c,s,n]);return m.a.createElement(P.a,{style:[I.container,u]},m.a.createElement(R.a,j({icon:t,style:I.iconButton,size:24,onPress:f,color:"function"===typeof a?a(s):a},i)))};k.displayName="TextInput.Icon",k.defaultProps={forceTextInputFocus:!0};var D,z,B,I=w.a.create({container:{position:"absolute",width:24,height:24,justifyContent:"center",alignItems:"center"},iconButton:{margin:0}}),H=k,M=n(59),W=n(38);!function(e){e.Icon="icon",e.Affix="affix"}(D||(D={})),function(e){e.Right="right",e.Left="left"}(z||(z={})),function(e){e.Outlined="outlined",e.Flat="flat"}(B||(B={}));var V=m.a.createContext({textStyle:{fontFamily:"",color:""},topPosition:null,side:z.Left}),X=function(e){var t=e.affix,n=e.side,o=e.textStyle,r=e.topPosition,a=e.onLayout,i=e.visible,l=e.paddingHorizontal;return m.a.createElement(V.Provider,{value:{side:n,textStyle:o,topPosition:r,onLayout:a,visible:i,paddingHorizontal:l}},t)},Y=function(e){var t=e.text,n=e.textStyle,o=e.theme,r=m.a.useContext(V),a=r.textStyle,i=r.onLayout,l=r.topPosition,u=r.side,s=r.visible,c=r.paddingHorizontal,f=A()(o.colors.text).alpha(o.dark?.7:.54).rgb().string(),d="number"===typeof c?c:12,p=L()({top:l},u,d);return m.a.createElement(v.a.View,{style:[N.container,p,{opacity:(null===s||void 0===s?void 0:s.interpolate({inputRange:[0,1],outputRange:[1,0]}))||1}],onLayout:i},m.a.createElement(M.a,{style:[{color:f},a,n]},t))};Y.displayName="TextInput.Affix";var N=w.a.create({container:{position:"absolute",justifyContent:"center",alignItems:"center"}}),U=Object(W.c)(Y);function G(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function J(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?G(Object(n),!0).forEach((function(t){L()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):G(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function q(){return(q=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}function K(e){var t=e.left,n=e.right,o=[];return(t||n)&&[{side:z.Left,adornment:t},{side:z.Right,adornment:n}].forEach((function(e){var t,n=e.side,r=e.adornment;r&&m.a.isValidElement(r)&&(r.type===U?t=D.Affix:r.type===H&&(t=D.Icon),o.push({side:n,type:t}))})),o}function Q(e){var t=e.adornmentConfig,n=e.leftAffixWidth,o=e.rightAffixWidth,r=e.paddingHorizontal,a=e.inputOffset,i=void 0===a?0:a,l=e.mode;return t.length?t.map((function(e){var t,a=e.type,u=e.side,s=u===z.Left,c=l===B.Outlined?20:12,f="padding".concat(Z(u)),d=(s?n:o)+("number"===typeof r?r:c),p=a===D.Affix,h="margin".concat(Z(u));return t={},L()(t,h,p?0:d),L()(t,f,p?d:i),t})).reduce((function(e,t){return J(J({},e),t)}),{}):[{}]}var Z=function(e){return e.charAt(0).toUpperCase()+e.slice(1)},$=function(e){var t=e.adornmentConfig,n=e.left,o=e.right,r=e.onAffixChange,a=e.textStyle,i=e.visible,l=e.topPosition,u=e.isTextInputFocused,s=e.forceFocus,c=e.paddingHorizontal;return t.length?m.a.createElement(m.a.Fragment,null,t.map((function(e){var t,f=e.type,d=e.side;d===z.Left?t=n:d===z.Right&&(t=o);var p={key:d,side:d,testID:"".concat(d,"-").concat(f,"-adornment"),isTextInputFocused:u,paddingHorizontal:c};return f===D.Icon?m.a.createElement(F,q({},p,{icon:t,topPosition:l[D.Icon],forceFocus:s})):f===D.Affix?m.a.createElement(X,q({},p,{topPosition:l[D.Affix][d],affix:t,textStyle:a,onLayout:r[d],visible:i})):null}))):null},_=n(442);function ee(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function te(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?ee(Object(n),!0).forEach((function(t){L()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):ee(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var ne=function(e){var t=e.parentState,n=e.labelBackground,o=e.labelProps,r=o.label,a=o.error,i=o.onLayoutAnimatedText,l=o.hasActiveOutline,u=o.activeColor,s=o.placeholderStyle,c=o.baseLabelTranslateX,f=o.baseLabelTranslateY,d=o.font,p=o.fontSize,h=o.fontWeight,g=o.placeholderOpacity,b=o.wiggleOffsetX,y=o.labelScale,x=o.topPosition,O=o.paddingOffset,C=o.placeholderColor,L=o.errorColor,P=o.labelTranslationXOffset,T={transform:[{translateX:t.labeled.interpolate({inputRange:[0,1],outputRange:[c,P||0]})}]},S=te(te({},d),{},{fontSize:p,fontWeight:h,transform:[{translateX:t.error.interpolate({inputRange:[0,.5,1],outputRange:[0,t.value&&a?b:0,0]})},{translateY:t.labeled.interpolate({inputRange:[0,1],outputRange:[f,0]})},{scale:t.labeled.interpolate({inputRange:[0,1],outputRange:[y,1]})}]});return r?m.a.createElement(v.a.View,{pointerEvents:"none",style:[w.a.absoluteFill,{opacity:t.value||t.focused?t.labelLayout.measured?1:0:1},T]},null===n||void 0===n?void 0:n({parentState:t,labelStyle:S,labelProps:e.labelProps}),m.a.createElement(_.a,{onLayout:i,style:[s,{top:x},S,O||{},{color:u,opacity:t.labeled.interpolate({inputRange:[0,1],outputRange:[l?1:0,0]})}],numberOfLines:1},r),m.a.createElement(_.a,{style:[s,{top:x},S,O,{color:a&&L?L:C,opacity:g}],numberOfLines:1},r)):null},oe=n(16),re=n.n(oe),ae=function(e){var t=e.parentState,n=e.labelProps,o=n.placeholderStyle,r=n.baseLabelTranslateX,a=n.topPosition,i=n.hasActiveOutline,l=n.label,u=n.backgroundColor,s=e.labelStyle,c=i||t.value,f=t.labeled.interpolate({inputRange:[0,1],outputRange:[c?1:0,0]}),d=Object(W.b)().roundness,p={transform:[{translateX:t.labeled.interpolate({inputRange:[0,1],outputRange:[-r,0]})}]};return l?[y.createElement(v.a.View,{key:"labelBackground-view",pointerEvents:"none",style:[w.a.absoluteFill,ie.view,{backgroundColor:u,opacity:f,bottom:Math.max(d,2)},p]}),y.createElement(_.a,{key:"labelBackground-text",style:[o,s,ie.outlinedLabel,{top:a+1,backgroundColor:u,opacity:f,transform:[].concat(re()(s.transform),[{scaleY:t.labeled.interpolate({inputRange:[0,1],outputRange:[.2,1]})}])}],numberOfLines:1},l)]:null},ie=w.a.create({view:{position:"absolute",top:6,left:10,width:8},outlinedLabel:{position:"absolute",left:18,paddingHorizontal:0,color:"transparent"}}),le=function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:0,n=arguments.length>2&&void 0!==arguments[2]?arguments[2]:0,o=t>0?t:0;return Math.floor((o-e)/2+n)},ue=function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:0,n=arguments.length>2?arguments[2]:void 0,o=t>0?t:e;return t>0?t:o<n?n:o},se=function(e){var t=e.height,n=e.multiline,o=void 0!==n&&n,r=0;return o&&(r=t&&o?ce(e):fe(e)),Math.max(0,r)},ce=function(e){return e.dense?10:20},fe=function(e){var t=e.topPosition,n=e.fontSize,o=e.multiline,r=e.scale,a=e.dense,i=e.offset,l=e.isAndroid,u=r*n,s=Math.floor(t/2);return s=s+Math.floor((u-n)/2)-(r<1?i/2:0),o&&l&&(s=Math.min(a?i/2:i,s)),s},de=function(e,t){return e.interpolate({inputRange:[0,1],outputRange:[t?0:1,1]})};function pe(e){var t=e.height,n=e.paddingTop;return n+(t-n-e.paddingBottom-e.affixHeight)/2}function he(e){return(e.height-e.affixHeight+e.labelYOffset)/2}function ge(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function be(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?ge(Object(n),!0).forEach((function(t){L()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):ge(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function ye(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}var me,ve,xe,Oe=function(e){d()(o,e);var t,n=(t=o,function(){var e,n=b()(t);if(ye()){var o=b()(this).constructor;e=Reflect.construct(n,arguments,o)}else e=n.apply(this,arguments);return h()(this,e)});function o(){return i()(this,o),n.apply(this,arguments)}return u()(o,[{key:"render",value:function(){var e,t,n,o,a,i,l,u,s=this.props,c=s.disabled,f=s.editable,d=s.label,p=s.error,h=s.selectionColor,g=(s.underlineColor,s.dense),b=s.style,m=s.theme,v=s.render,x=s.multiline,C=s.parentState,S=s.innerRef,R=s.onFocus,j=s.forceFocus,E=s.onBlur,F=s.onChangeText,k=s.onLayoutAnimatedText,B=s.onLeftAffixLayoutChange,I=s.onRightAffixLayoutChange,H=s.left,M=s.right,W=s.placeholderTextColor,V=r()(s,["disabled","editable","label","error","selectionColor","underlineColor","dense","style","theme","render","multiline","parentState","innerRef","onFocus","forceFocus","onBlur","onChangeText","onLayoutAnimatedText","onLeftAffixLayoutChange","onRightAffixLayoutChange","left","right","placeholderTextColor"]),X=K({left:H,right:M}),Y=m.colors,N=m.fonts.regular,U=C.focused||p,G=w.a.flatten(b)||{},J=G.fontSize,q=G.fontWeight,Z=G.height,_=G.backgroundColor,ee=void 0===_?Y.background:_,te=G.textAlign,oe=r()(G,["fontSize","fontWeight","height","backgroundColor","textAlign"]),re=J||16;c?(o=a=A()(Y.text).alpha(.54).rgb().string(),l=i=Y.disabled):(o=Y.text,a=p?Y.error:Y.primary,l=i=Y.placeholder,u=Y.error);var ie=12/re,ce=16/re,fe=C.labelLayout.width,pe=C.labelLayout.height,ge=fe/2,ye=pe/2,me=(T.a.isRTL?1:-1)*(ge-ie*fe/2-(re-12)*ie),ve=0;X.some((function(e){var t=e.side,n=e.type;return t===z.Left&&n===D.Icon}))&&(ve=28*(T.a.isRTL?-1:1));var xe=ue(pe,Z,(g?48:64)-8),Oe=le(pe,xe,8);Z&&"number"!==typeof Z&&console.warn("Currently we support only numbers in height prop");var Ce={height:Z?+Z:null,labelHalfHeight:ye,offset:8,multiline:x||null,dense:g||null,topPosition:Oe,fontSize:re,label:d,scale:ce,isAndroid:"android"===O.a.OS,styles:w.a.flatten(g?Pe.inputOutlinedDense:Pe.inputOutlined)},we=se(Ce),Te=function(e){var t=e.pad,n=e.multiline,o=e.label,r=e.scale,a=e.height,i=e.fontSize,l=e.dense,u=e.offset,s=e.isAndroid,c=r*i,f=t;return a?{paddingTop:Math.max(0,(a-i)/2),paddingBottom:Math.max(0,(a-i)/2)}:(!s&&n&&(l&&(f+=o&&r<1?Math.min(u,c/2*r):0),l||(f+=o?r<1?Math.min(u,c*r):Math.min(u/2,c*r):r<1?Math.min(u/2,c*r):0),f=Math.floor(f)),{paddingTop:f,paddingBottom:f})}(be(be({},Ce),{},{pad:we})),Se=-ye-(Oe+-6),Ae={label:d,onLayoutAnimatedText:k,placeholderOpacity:U?de(C.labeled,U):C.labelLayout.measured?1:0,error:p,placeholderStyle:Pe.placeholder,baseLabelTranslateY:Se,baseLabelTranslateX:me,font:N,fontSize:re,fontWeight:q,labelScale:ie,wiggleOffsetX:4,topPosition:Oe,hasActiveOutline:U,activeColor:a,placeholderColor:l,backgroundColor:ee,errorColor:u,labelTranslationXOffset:ve},Re=Z||(g?48:64),je=C.leftLayout,Ee=C.rightLayout,Fe=he({height:Re,affixHeight:je.height||0,labelYOffset:6}),ke=he({height:Re,affixHeight:Ee.height||0,labelYOffset:6}),De=he({height:Re,affixHeight:24,labelYOffset:6}),ze=Q({adornmentConfig:X,rightAffixWidth:M&&Ee.width||24,leftAffixWidth:H&&je.width||24,mode:"outlined"}),Be=(e={},L()(e,z.Left,Fe),L()(e,z.Right,ke),e),Ie=(t={},L()(t,z.Left,B),L()(t,z.Right,I),t),He={adornmentConfig:X,forceFocus:j,topPosition:(n={},L()(n,D.Icon,De),L()(n,D.Affix,Be),n),onAffixChange:Ie,isTextInputFocused:C.focused};return X.length&&(He=be(be({},He),{},{left:H,right:M,textStyle:be(be({},N),{},{fontSize:re,fontWeight:q}),visible:this.props.parentState.labeled})),y.createElement(P.a,{style:oe},y.createElement(P.a,null,y.createElement(Le,{theme:m,hasActiveOutline:U,activeColor:a,outlineColor:i,backgroundColor:ee}),y.createElement(P.a,{style:[Pe.labelContainer,{paddingTop:8,minHeight:Re}]},y.createElement(ne,{parentState:C,labelProps:Ae,labelBackground:ae}),null===v||void 0===v?void 0:v(be(be({},V),{},{ref:S,onChangeText:F,placeholder:d?C.placeholder:this.props.placeholder,placeholderTextColor:W||l,editable:!c&&f,selectionColor:"undefined"===typeof h?a:h,onFocus:R,onBlur:E,underlineColorAndroid:"transparent",multiline:x,style:[Pe.input,!x||x&&Z?{height:xe}:{},Te,be(be({},N),{},{fontSize:re,fontWeight:q,color:o,textAlignVertical:x?"top":"center",textAlign:te||(T.a.isRTL?"right":"left")}),"web"===O.a.OS&&{outline:"none"},ze]}))),y.createElement($,He)))}}]),o}(y.Component);xe={disabled:!1,error:!1,multiline:!1,editable:!0,render:function(e){return y.createElement(x.a,e)}},(ve="defaultProps")in(me=Oe)?Object.defineProperty(me,ve,{value:xe,enumerable:!0,configurable:!0,writable:!0}):me[ve]=xe;var Ce=Oe,Le=function(e){var t=e.theme,n=e.hasActiveOutline,o=e.activeColor,r=e.outlineColor,a=e.backgroundColor;return y.createElement(P.a,{pointerEvents:"none",style:[Pe.outline,{backgroundColor:a,borderRadius:t.roundness,borderWidth:n?2:1,borderColor:n?o:r}]})},Pe=w.a.create({placeholder:{position:"absolute",left:0,paddingHorizontal:14},outline:{position:"absolute",left:0,right:0,top:6,bottom:0},labelContainer:{paddingBottom:0},input:{flexGrow:1,paddingHorizontal:14,margin:0,zIndex:1},inputOutlined:{paddingTop:8,paddingBottom:8},inputOutlinedDense:{paddingTop:4,paddingBottom:4}});function we(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function Te(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?we(Object(n),!0).forEach((function(t){L()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):we(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function Se(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}var Ae=function(e){d()(o,e);var t,n=(t=o,function(){var e,n=b()(t);if(Se()){var o=b()(this).constructor;e=Reflect.construct(n,arguments,o)}else e=n.apply(this,arguments);return h()(this,e)});function o(){return i()(this,o),n.apply(this,arguments)}return u()(o,[{key:"render",value:function(){var e,t,n,o=this.props,a=o.disabled,i=o.editable,l=o.label,u=o.error,s=o.selectionColor,c=o.underlineColor,f=o.dense,d=o.style,p=o.theme,h=o.render,g=o.multiline,b=o.parentState,m=o.innerRef,v=o.onFocus,x=o.forceFocus,C=o.onBlur,S=o.onChangeText,R=o.onLayoutAnimatedText,j=o.onLeftAffixLayoutChange,E=o.onRightAffixLayoutChange,F=o.left,k=o.right,I=o.placeholderTextColor,H=r()(o,["disabled","editable","label","error","selectionColor","underlineColor","dense","style","theme","render","multiline","parentState","innerRef","onFocus","forceFocus","onBlur","onChangeText","onLayoutAnimatedText","onLeftAffixLayoutChange","onRightAffixLayoutChange","left","right","placeholderTextColor"]),M=p.colors,W=p.fonts.regular,V=b.focused||u,X=w.a.flatten(d)||{},Y=X.fontSize,N=X.fontWeight,U=X.height,G=X.paddingHorizontal,J=X.textAlign,q=r()(X,["fontSize","fontWeight","height","paddingHorizontal","textAlign"]),Z=Y||16,_=void 0!==G&&"number"===typeof G,ee=K({left:F,right:k}),te=function(e){var t=e.adornmentConfig,n=12,o=12;return t.forEach((function(e){var t=e.type,r=e.side;t===D.Icon&&r===z.Left?n=44:r===z.Right&&(t===D.Affix||t===D.Icon)&&(o=44)})),{paddingLeft:n,paddingRight:o}}({adornmentConfig:ee}),oe=te.paddingLeft,re=te.paddingRight;_&&(oe=G,re=G);var ae,ie,ce,fe,he,ge=b.leftLayout,be=b.rightLayout,ye=Q({adornmentConfig:ee,rightAffixWidth:k&&be.width||24,leftAffixWidth:F&&ge.width||24,paddingHorizontal:G,inputOffset:8,mode:B.Flat});a?(ae=ie=A()(M.text).alpha(.54).rgb().string(),fe=M.disabled,ce="transparent"):(ae=M.text,ie=u?M.error:M.primary,fe=M.placeholder,he=M.error,ce=c||M.disabled);var me={backgroundColor:p.dark?A()(M.background).lighten(.24).rgb().string():A()(M.background).darken(.06).rgb().string(),borderTopLeftRadius:p.roundness,borderTopRightRadius:p.roundness},ve=12/Z,xe=16/Z,Oe=b.labelLayout.width,Ce=b.labelLayout.height,Le=Oe/2,Pe=Ce/2,we=(T.a.isRTL?1:-1)*(Le-ve*Oe/2)+(1-ve)*(T.a.isRTL?-1:1)*oe,Se=f?(l?52:40)-24:34,Ae=ue(Ce,U,Se),Re=le(Ce,Ae,g&&U||U?0:Se/2);U&&"number"!==typeof U&&console.warn("Currently we support only numbers in height prop");var Fe={height:U?+U:null,labelHalfHeight:Pe,offset:8,multiline:g||null,dense:f||null,topPosition:Re,fontSize:Z,label:l,scale:xe,isAndroid:"android"===O.a.OS,styles:w.a.flatten(f?Ee.inputFlatDense:Ee.inputFlat)},ke=se(Fe),De=function(e){var t=e.pad,n=e.scale,o=e.multiline,r=e.label,a=e.height,i=e.offset,l=e.dense,u=e.fontSize,s=e.isAndroid,c=e.styles,f=t,d=f,p=f,h=c.paddingTop,g=c.paddingBottom,b=n*u;if(!o)return r?{paddingTop:h,paddingBottom:g}:{paddingTop:f,paddingBottom:f};if(r)d=h,p=g,s||(l&&(d+=Math.min(f,b*n)-f/2),l||(d+=n<1?Math.min(i/2,b*n):Math.min(f,b*n)-i/2)),d=Math.floor(d);else{if(a)return{paddingTop:Math.max(0,(a-u)/2),paddingBottom:Math.max(0,(a-u)/2)};s||(l&&(f+=n<1?Math.min(i/2,u/2*n):Math.min(i/2,n)),l||(f+=n<1?Math.min(i,u*n):Math.min(u,i/2*n)),d=f=Math.floor(f),p=f)}return{paddingTop:Math.max(0,d),paddingBottom:Math.max(0,p)}}(Te(Te({},Fe),{},{pad:ke})),ze=-Pe-(Re+-18),Be=V?de(b.labeled,V):b.labelLayout.measured?1:0,Ie=U||(f?l?52:40:64),He=Ae+(U?0:f?24:30),Me=(He-24)/2,We=ge.height?pe(Te(Te({height:He},De),{},{affixHeight:ge.height})):null,Ve=be.height?pe(Te(Te({height:He},De),{},{affixHeight:be.height})):null,Xe={label:l,onLayoutAnimatedText:R,placeholderOpacity:Be,error:u,placeholderStyle:Ee.placeholder,baseLabelTranslateY:ze,baseLabelTranslateX:we,font:W,fontSize:Z,fontWeight:N,labelScale:ve,wiggleOffsetX:4,topPosition:Re,paddingOffset:{paddingLeft:oe,paddingRight:re},hasActiveOutline:V,activeColor:ie,placeholderColor:fe,errorColor:he},Ye=(e={},L()(e,z.Left,We),L()(e,z.Right,Ve),e),Ne=(t={},L()(t,z.Left,j),L()(t,z.Right,E),t),Ue={paddingHorizontal:G,adornmentConfig:ee,forceFocus:x,topPosition:(n={},L()(n,D.Affix,Ye),L()(n,D.Icon,Me),n),onAffixChange:Ne,isTextInputFocused:this.props.parentState.focused};return ee.length&&(Ue=Te(Te({},Ue),{},{left:F,right:k,textStyle:Te(Te({},W),{},{fontSize:Z,fontWeight:N}),visible:this.props.parentState.labeled})),y.createElement(P.a,{style:[me,q]},y.createElement(je,{parentState:b,underlineColorCustom:ce,error:u,colors:M,activeColor:ie}),y.createElement(P.a,{style:[Ee.labelContainer,{minHeight:Ie}]},y.createElement(ne,{parentState:b,labelProps:Xe}),null===h||void 0===h?void 0:h(Te(Te({},H),{},{ref:m,onChangeText:S,placeholder:l?b.placeholder:this.props.placeholder,placeholderTextColor:null!==I&&void 0!==I?I:fe,editable:!a&&i,selectionColor:"undefined"===typeof s?ie:s,onFocus:v,onBlur:C,underlineColorAndroid:"transparent",multiline:g,style:[Ee.input,{paddingLeft:oe,paddingRight:re},!g||g&&U?{height:He}:{},De,Te(Te({},W),{},{fontSize:Z,fontWeight:N,color:ae,textAlignVertical:g?"top":"center",textAlign:J||(T.a.isRTL?"right":"left")}),"web"===O.a.OS&&{outline:"none"},ye]}))),y.createElement($,Ue))}}]),o}(y.Component);!function(e,t,n){t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n}(Ae,"defaultProps",{disabled:!1,error:!1,multiline:!1,editable:!0,render:function(e){return y.createElement(x.a,e)}});var Re=Ae,je=function(e){var t=e.parentState,n=e.error,o=e.colors,r=e.activeColor,a=e.underlineColorCustom,i=t.focused?r:a;return n&&(i=o.error),y.createElement(v.a.View,{style:[Ee.underline,{backgroundColor:i,transform:[{scaleY:t.focused?1:.5}]}]})},Ee=w.a.create({placeholder:{position:"absolute",left:0},underline:{position:"absolute",left:0,right:0,bottom:0,height:2},labelContainer:{paddingTop:0,paddingBottom:0},input:{flexGrow:1,margin:0,zIndex:1},inputFlat:{paddingTop:24,paddingBottom:4},inputFlatDense:{paddingTop:22,paddingBottom:2}});function Fe(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}function ke(){return(ke=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}function De(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var ze=function(e){d()(o,e);var t,n=(t=o,function(){var e,n=b()(t);if(Fe()){var o=b()(this).constructor;e=Reflect.construct(n,arguments,o)}else e=n.apply(this,arguments);return h()(this,e)});function o(){var e;i()(this,o);for(var t=arguments.length,r=new Array(t),a=0;a<t;a++)r[a]=arguments[a];return e=n.call.apply(n,[this].concat(r)),De(c()(e),"validInputValue",void 0!==e.props.value?e.props.value:e.props.defaultValue),De(c()(e),"state",{labeled:new v.a.Value(e.validInputValue?0:1),error:new v.a.Value(e.props.error?1:0),focused:!1,placeholder:"",value:e.validInputValue,labelLayout:{measured:!1,width:0,height:0},leftLayout:{width:null,height:null},rightLayout:{width:null,height:null}}),De(c()(e),"ref",void 0),De(c()(e),"showPlaceholder",(function(){e.timer&&clearTimeout(e.timer),e.timer=setTimeout((function(){return e.setState({placeholder:e.props.placeholder})}),50)})),De(c()(e),"hidePlaceholder",(function(){return e.setState({placeholder:""})})),De(c()(e),"timer",void 0),De(c()(e),"root",void 0),De(c()(e),"showError",(function(){var t=e.props.theme.animation.scale;v.a.timing(e.state.error,{toValue:1,duration:150*t,useNativeDriver:O.a.select({ios:!1,default:!0})}).start()})),De(c()(e),"hideError",(function(){var t=e.props.theme.animation.scale;v.a.timing(e.state.error,{toValue:0,duration:180*t,useNativeDriver:O.a.select({ios:!1,default:!0})}).start()})),De(c()(e),"restoreLabel",(function(){var t=e.props.theme.animation.scale;v.a.timing(e.state.labeled,{toValue:1,duration:150*t,useNativeDriver:O.a.select({ios:!1,default:!0})}).start()})),De(c()(e),"minimizeLabel",(function(){var t=e.props.theme.animation.scale;v.a.timing(e.state.labeled,{toValue:0,duration:180*t,useNativeDriver:O.a.select({ios:!1,default:!0})}).start()})),De(c()(e),"onLeftAffixLayoutChange",(function(t){e.setState({leftLayout:{height:t.nativeEvent.layout.height,width:t.nativeEvent.layout.width}})})),De(c()(e),"onRightAffixLayoutChange",(function(t){e.setState({rightLayout:{width:t.nativeEvent.layout.width,height:t.nativeEvent.layout.height}})})),De(c()(e),"handleFocus",(function(t){!e.props.disabled&&e.props.editable&&(e.setState({focused:!0}),e.props.onFocus&&e.props.onFocus(t))})),De(c()(e),"handleBlur",(function(t){e.props.editable&&(e.setState({focused:!1}),e.props.onBlur&&e.props.onBlur(t))})),De(c()(e),"handleChangeText",(function(t){e.props.editable&&(e.setState({value:t}),e.props.onChangeText&&e.props.onChangeText(t))})),De(c()(e),"handleLayoutAnimatedText",(function(t){e.setState({labelLayout:{width:t.nativeEvent.layout.width,height:t.nativeEvent.layout.height,measured:!0}})})),De(c()(e),"forceFocus",(function(){var t;return null===(t=e.root)||void 0===t?void 0:t.focus()})),e}return u()(o,[{key:"componentDidUpdate",value:function(e,t){var n=t.focused!==this.state.focused,o=t.value!==this.state.value,r=t.labelLayout!==this.state.labelLayout,a=e.label!==this.props.label,i=e.error!==this.props.error;(n||o||r)&&(this.state.value||this.state.focused?this.minimizeLabel():this.restoreLabel()),(n||a)&&(this.state.focused||!this.props.label?this.showPlaceholder():this.hidePlaceholder()),i&&(this.props.error?this.showError():this.hideError())}},{key:"componentWillUnmount",value:function(){this.timer&&clearTimeout(this.timer)}},{key:"setNativeProps",value:function(e){return this.root&&this.root.setNativeProps(e)}},{key:"isFocused",value:function(){return this.root&&this.root.isFocused()}},{key:"clear",value:function(){return this.root&&this.root.clear()}},{key:"focus",value:function(){return this.root&&this.root.focus()}},{key:"blur",value:function(){return this.root&&this.root.blur()}},{key:"render",value:function(){var e=this,t=this.props,n=t.mode,o=r()(t,["mode"]);return"outlined"===n?y.createElement(Ce,ke({},o,{value:this.state.value,parentState:this.state,innerRef:function(t){e.root=t},onFocus:this.handleFocus,forceFocus:this.forceFocus,onBlur:this.handleBlur,onChangeText:this.handleChangeText,onLayoutAnimatedText:this.handleLayoutAnimatedText,onLeftAffixLayoutChange:this.onLeftAffixLayoutChange,onRightAffixLayoutChange:this.onRightAffixLayoutChange})):y.createElement(Re,ke({},o,{value:this.state.value,parentState:this.state,innerRef:function(t){e.root=t},onFocus:this.handleFocus,forceFocus:this.forceFocus,onBlur:this.handleBlur,onChangeText:this.handleChangeText,onLayoutAnimatedText:this.handleLayoutAnimatedText,onLeftAffixLayoutChange:this.onLeftAffixLayoutChange,onRightAffixLayoutChange:this.onRightAffixLayoutChange}))}}],[{key:"getDerivedStateFromProps",value:function(e,t){return{value:"undefined"!==typeof e.value?e.value:t.value}}}]),o}(y.Component);De(ze,"Icon",H),De(ze,"Affix",U),De(ze,"defaultProps",{mode:"flat",dense:!1,disabled:!1,error:!1,multiline:!1,editable:!0,render:function(e){return y.createElement(x.a,e)}});t.a=Object(W.c)(ze)},442:function(e,t,n){"use strict";var o=n(7),r=n.n(o),a=n(13),i=n.n(a),l=n(0),u=n(8),s=n(31),c=n(4),f=n(38);function d(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function p(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?d(Object(n),!0).forEach((function(t){r()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):d(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function h(){return(h=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}var g=c.a.create({text:{textAlign:"left"}});t.a=Object(f.c)((function(e){var t=e.style,n=e.theme,o=i()(e,["style","theme"]),r=s.a.isRTL?"rtl":"ltr";return l.createElement(u.a.Text,h({},o,{style:[g.text,p(p({},n.fonts.regular),{},{color:n.colors.text,writingDirection:r}),t]}))}))}}]);
//# sourceMappingURL=0.63fd9fa0.chunk.js.map