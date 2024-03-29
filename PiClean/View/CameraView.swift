import SwiftUI
import CoreML
import PhotosUI
import Vision

extension UIImage: Identifiable
{
    
func pixelBuffer() -> CVPixelBuffer? {
    
let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
var pixelBuffer: CVPixelBuffer?
let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.size.width),
                                         Int(self.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: Int(self.size.width),
                                height: Int(self.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        guard let cgImage = self.cgImage, let ctx = context else {
            return nil
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        return buffer
    }
} // Used to convert a UIImage into a CVPixelBuffer

struct CameraView: View {
    
@State private var showCamera = false
@State private var showClass = false
@State private var isShowingSheet = false
@State private var isFlipped = false
@EnvironmentObject var vm : ViewModel
    
var body: some View {
GeometryReader { geometry in
            
            VStack {
                if vm.selectedImage1 != nil {
                    AfterPage()
                }
                
                else{
                    
            ZStack {
                        Background()
                       
                        VStack (alignment: .center , spacing: 30) {
                            
                            Text("Lets Save Our Planet!")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .multilineTextAlignment(.center)
                                .background(
                                    Rectangle()
                                    .foregroundColor(Color.black)
                                    .cornerRadius(10)
                                          )
                            
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 250, height: 250)
                                .rotation3DEffect(
                                    Angle(degrees: isFlipped ? 180 : 0),
                                    axis: (x: 0.0, y: 1.0, z: 0.0)
                                )
                             
                            Button(action: {
                                isShowingSheet.toggle()
                                
                            }) {
                                ZStack{
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("ButtonColor"))
                                        .frame(width:148, height: 44, alignment: .center)
                                        .cornerRadius(12)
                                    
                                    
                                    Text("Get Started")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .accessibilityLabel("This is a button to get started")
                                }
                                
                            }  .padding(.top, geometry.size.height * 0.3)
                            
                        }
                        
                    }
                
                    .fullScreenCover(isPresented: self.$showCamera ) {
                        accessCameraView(selectedImage1: $vm.selectedImage1)
                            .interactiveDismissDisabled()
                            .ignoresSafeArea()
                        
                    } // end fullScreenCover
                    
                    .sheet(isPresented: $isShowingSheet) {
                        
                        ZStack{
                            VStack{
                                Spacer()
                                    .frame(height: 50)
                                
                                Text("""
                                     Snap a quick picture of your current 
                                     mess, before starting to clean up.
                                     """)
                                
                                .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.white)
                                    .multilineTextAlignment(.center)
                                
                                Spacer()
                                    .frame(height: 50)
                                
                                Text(" Lets make a positive impact together")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.gray)
                                    .multilineTextAlignment(.center)
                                
                                
                                Button(action: {
                                    self.showCamera.toggle()
                                }) {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color("ButtonColor"))
                                            .frame(width:155, height: 50, alignment: .center)
                                            .cornerRadius(12)
                                       
                                        Text("Take a Photo")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        
                                            .accessibilityLabel("Take a Photo button")
                                        
                                    }
                                   
                                }.padding(.top, 140)
                            }
                            .environment(\.colorScheme, .dark)
                            .presentationDetents([.medium, .large])
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color("SheetColor"))
                            
                        }
                        
                    }.onDisappear(){
                        
                    }
                    
                    if vm.classificationResult2 == "UnClean" {
                        Text("UnClean")
                            .opacity(0)
                            .alert("Oopss!! You didn't clean well", isPresented: $vm.isShowingUnCleanAlert, actions: {
                                Button("Try Again") {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                                self.isFlipped.toggle()
                                            }
                                }
                            })
                    }
                    
                    if vm.classificationResult2 == "Clean" {
                        
                        Text("Clean")
                            .opacity(0)
                            .alert("Thank you for the positive impact you've made on the environment", isPresented: $vm.isShowingCleanAlert, actions: {
                                
                                Button("Continue") {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                                self.isFlipped.toggle()
                                            }
                                }
                            })
                            }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        var imageName: String {
            print(vm.Count)
                if vm.Count == 1 {
                    return "Clean1"
                }
              else  if vm.Count == 2 {
                    return "Clean2"
                }
            else  if vm.Count == 3 {
                    return "Clean3"
                }
            else  if vm.Count >= 4{
                    return "cleanPlanet"
                }
          
            return "DirtyPlanet"
        }//change the planet based on the progress

    }
    
    struct accessCameraView:
                                
    UIViewControllerRepresentable {
        
        @Binding var selectedImage1: UIImage?
        @Environment(\.presentationMode) var isPresented
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = context.coordinator
            return imagePicker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
            
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(picker: self)
            
        }
    } 
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var picker: accessCameraView
        let model: PiCleanClassifier_1
        var classificationResult1: String?
        
        init(picker: accessCameraView) {
            self.picker = picker
            self.model = try! PiCleanClassifier_1(configuration: MLModelConfiguration())
            super.init()
        }
        
        func processImage(_ image: UIImage) {
            if let pixelBuffer = image.pixelBuffer() {
                do {
                    let output = try model.prediction(input: PiCleanClassifier_1Input(image: pixelBuffer))
                    self.classificationResult1 = output.target
                    print("Classification result: \( String(describing: self.classificationResult1))")
                    
                } catch {
                    print("Error: \(error)")
                }
                
            }
            
        }
        
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let selectedImage1 = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                return
            }
            self.picker.selectedImage1 = selectedImage1
            processImage(selectedImage1)
            
            //selectedImage variable represents the image selected or captured by the user using the camera
            
            self.picker.isPresented.wrappedValue.dismiss()
        } // This function gets called when the user has selected or taken a photo using the camera
       
   // }
}
    #Preview {
       CameraView()
            .environment(\.locale, .init(identifier:"PiClean"))
            .environmentObject(ViewModel())

        
    }


