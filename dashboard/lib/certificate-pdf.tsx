import "server-only";
import path from "node:path";
import { Document,Font,Page,Text,View,renderToBuffer } from "@react-pdf/renderer";

Font.register({family:"Cairo",src:path.join(process.cwd(),"app/fonts/Cairo.ttf")});
export function certificatePdf({name,kind,date,center,id}:{name:string;kind:string;date:string;center:string;id:string}){
  return renderToBuffer(<Document title={`شهادة ${name}`} author={center}>
    <Page size="A4" orientation="landscape" style={{fontFamily:"Cairo",padding:40,color:"#14372b",backgroundColor:"#faf9f4"}}>
      <View style={{borderWidth:2,borderColor:"#0c7c59",padding:35,flexGrow:1,alignItems:"center",justifyContent:"center"}}>
        <Text style={{fontSize:18,marginBottom:20}}>{center}</Text>
        <Text style={{fontSize:34,marginBottom:25}}>شهادة {kind}</Text>
        <Text style={{fontSize:16,marginBottom:10}}>تُمنح هذه الشهادة إلى</Text>
        <Text style={{fontSize:28,marginBottom:25}}>{name}</Text>
        <Text style={{fontSize:16,marginBottom:15}}>تقديرًا لجهوده في تعلّم وحفظ القرآن الكريم</Text>
        <Text style={{fontSize:13,marginBottom:25}}>{date}</Text>
        <Text style={{fontSize:9,color:"#51645a"}}>{id}</Text>
      </View>
    </Page>
  </Document>);
}
