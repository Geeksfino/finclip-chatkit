//
//  NoteContextProvider.h
//  SimpleObjC
//
//  Example Objective-C context provider demonstrating how to implement
//  a custom context provider for the ConvoUI composer.
//
//  This provider allows users to attach a text note to their message.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ConvoUI/FinConvoComposerContextProvider.h>

NS_ASSUME_NONNULL_BEGIN

/// Example context provider that allows users to attach a text note
/// 
/// This demonstrates:
/// - Custom collector view (text input)
/// - Custom preview chip (styled note preview)
/// - Custom detail view (full note display)
/// - Context item encoding for transport
@interface NoteContextProvider : NSObject <FinConvoComposerContextProvider>

@end

NS_ASSUME_NONNULL_END

