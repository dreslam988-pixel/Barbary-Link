// SPDX-License-Identifier: GPL-3.0-or-later
//! Original Barbary Link phone-and-monitor icon, independent of the upstream trademark.
fn segment(x: f32, y: f32, a: (f32,f32), b: (f32,f32)) -> f32 {
    let (dx,dy)=(b.0-a.0,b.1-a.1);
    let t=(((x-a.0)*dx+(y-a.1)*dy)/(dx*dx+dy*dy)).clamp(0.0,1.0);
    ((x-a.0-t*dx).powi(2)+(y-a.1-t*dy).powi(2)).sqrt()
}
fn stroke(x:f32,y:f32,points:&[(f32,f32)],width:f32)->bool {
    points.windows(2).any(|p|segment(x,y,p[0],p[1])<=width)
}
fn pixel(x:f32,y:f32,glyph:Option<[u8;3]>)->Option<[u8;3]> {
    let monitor=[(23.,31.),(74.,31.),(74.,65.),(23.,65.),(23.,31.)];
    let stand=[(39.,66.),(39.,74.),(60.,74.)];
    let arrow=[(35.,43.),(48.,43.),(43.,38.),(48.,43.),(43.,48.)];
    let phone=[(63.,44.),(85.,44.),(87.,46.),(87.,80.),(85.,82.),(63.,82.),(61.,80.),(61.,46.),(63.,44.)];
    let screen=x>62.&&x<86.&&y>45.&&y<81.;
    let mint=[97,227,220];
    let mut c=None;
    if stroke(x,y,&monitor,2.)||stroke(x,y,&stand,2.)||stroke(x,y,&arrow,1.5){c=Some(mint);}
    if screen {c=if glyph.is_some(){None}else{Some([21,37,61])};}
    if stroke(x,y,&phone,1.5){c=Some([255,255,255]);}
    if stroke(x,y,&[(70.,76.),(78.,76.)],1.5){c=Some(mint);}
    c.map(|v|glyph.unwrap_or(v))
}
fn draw(size:usize,glyph:Option<[u8;3]>)->Vec<u8>{
    let mut out=vec![0;size*size*4];
    if size==0{return out;}
    for y in 0..size {for x in 0..size {
        let mut rgb=[0u32;3];let mut count=0;
        for sy in 0..4 {for sx in 0..4 {
            let px=(x as f32+(sx as f32+0.5)/4.)*108./size as f32;
            let py=(y as f32+(sy as f32+0.5)/4.)*108./size as f32;
            let radius=23.;let dx=(px-54.).abs()-31.;let dy=(py-54.).abs()-31.;
            let tile=dx.max(0.).hypot(dy.max(0.))+dx.max(dy).min(0.)<=radius;
            let c=pixel(px,py,glyph).or_else(||if glyph.is_none()&&tile{Some([12,21,38])}else{None});
            if let Some(c)=c{count+=1;for i in 0..3{rgb[i]+=c[i] as u32;}}
        }}
        if count>0{let i=(y*size+x)*4;for n in 0..3{out[i+n]=(rgb[n]/count) as u8;}out[i+3]=(count*255/16) as u8;}
    }}out
}
pub fn render(size:usize)->Vec<u8>{draw(size,None)}
#[allow(dead_code)]
pub fn render_glyph(size:usize,color:[u8;3])->Vec<u8>{draw(size,Some(color))}
#[cfg(test)]
mod tests {
    #[test] fn valid_image_sizes(){for n in [16,24,32,64,256]{assert_eq!(super::render(n).len(),n*n*4);}}
    #[test] fn corner_is_clear(){assert_eq!(super::render(32)[3],0);}
}
