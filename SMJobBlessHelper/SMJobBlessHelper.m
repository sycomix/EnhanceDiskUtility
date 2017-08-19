//
//  SMJobBlessHelper.m
//  EnhanceDiskUtility
//
//  Created by Nickolas Pylarinos on DONT_REALLY_REMEMBER.
//  Copyright © 2017 ulcheats. All rights reserved.
//

/*
 *  ARC is ** ENABLED **!
 */

#include <syslog.h>
#include <xpc/xpc.h>

#import <Foundation/Foundation.h>



NSTask * task = nil;        // ** TODO ** hmmm, make this more private??


//
//  ** TODO ** Add function for cleaning up files in /Library/LaunchDaemons, PrivilegedHelpers,
//
//
//  ** TODO * Handle the events indicating error --> terminate the helper.
//


static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    //
    //  This code waits for the following events: error-related events OR
    //
    
    
    syslog(LOG_NOTICE, "Received event in helper.");
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
        NSLog( @"got XPC ERROR event" );
	} else {
        //
        //  Read EnhanceDiskUtility's given |mode| and |mountPoint|
        //
        
        xpc_connection_t connection = xpc_dictionary_get_remote_connection(event);
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        
        const char * mode = xpc_dictionary_get_string( connection, "mode" );
        const char * mountPoint = xpc_dictionary_get_string( connection, "mountPoint" );
        
        NSLog( @"got START event" );
        
        //
        //  Reply that we got the START signal
        //
        
        //xpc_dictionary_set_string( reply, "reply", "STARTING" );
        //xpc_connection_send_message(remote, reply);
        
        //
        //  Start the Operation
        //
        
        for( NSString * pathComponent in [[[NSBundle mainBundle] resourceURL] pathComponents] )
            NSLog( @"%@", pathComponent );
        
        
        task = [[NSTask alloc] init];
        [task setLaunchPath:@"../../Resources/RepairPermissionsUtility"];
//        [task setArguments:@[ [NSString stringWithUTF8String:mode], [NSString stringWithUTF8String:mountPoint], @"--no-output"]];
        [task setArguments:@[ [NSString stringWithUTF8String:mode], [NSString stringWithUTF8String:mountPoint] ]];
        
        task.standardOutput = [NSPipe pipe];
        [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
            NSData *data = [file availableData]; // this will read to EOF, so call only once
            NSLog(@"Task output! %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            
            //                xpc_connection_send_message(, <#xpc_object_t  _Nonnull message#>)
        }];
        
        //            [task launch];
        //            [task waitUntilExit];
        //            [task release];
        
        return;
    }
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

int main(int argc, const char *argv[]) {
    
    xpc_connection_t service = xpc_connection_create_mach_service("org.npyl.EnhanceDiskUtility.SMJobBlessHelper",
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
    
    syslog(LOG_NOTICE, "Configuring connection event handler for helper");
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        __XPC_Connection_Handler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
    
    //xpc_release(service);

    return EXIT_SUCCESS;
}

